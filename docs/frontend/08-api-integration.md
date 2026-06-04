# API Integration

## CircleStream — Flutter ↔ Backend Integration Guide

---

## 1. Dio Client Setup

```dart
// lib/core/network/api_client.dart

import 'package:dio/dio.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(secureStorage: SecureStorage()),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
}
```

---

## 2. Auth Interceptor (Auto Token Refresh)

```dart
// lib/core/network/auth_interceptor.dart

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  bool _isRefreshing = false;

  AuthInterceptor({required SecureStorage secureStorage})
      : _storage = secureStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth endpoints
    if (options.path.startsWith('/auth/')) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) throw Exception('No refresh token');

        final response = await Dio().post(
          '${AppConstants.baseUrl}/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newToken = response.data['access_token'];
        await _storage.saveAccessToken(newToken);

        // Retry original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final retried = await Dio().fetch(err.requestOptions);
        return handler.resolve(retried);
      } catch (_) {
        // Refresh failed → logout
        await _storage.clear();
        // Trigger auth bloc logout event via global event bus
        authEventBus.fire(LogoutEvent());
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
```

---

## 3. Auth Repository

```dart
// lib/features/auth/data/auth_repository_impl.dart

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  AuthRepositoryImpl({required ApiClient api, required SecureStorage storage})
      : _api = api, _storage = storage;

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final response = await _api.post(Endpoints.login, data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      await _storage.saveTokens(
        accessToken: data['tokens']['access_token'],
        refreshToken: data['tokens']['refresh_token'],
      );

      return AuthResult(
        user: UserModel.fromJson(data['user']),
        accessToken: data['tokens']['access_token'],
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _api.post(Endpoints.logout, data: {'refresh_token': refreshToken});
    await _storage.clear();
  }
}
```

---

## 4. Upload Repository

```dart
// lib/features/camera/data/upload_repository_impl.dart

class UploadRepositoryImpl implements UploadRepository {
  final ApiClient _api;
  final Dio _rawDio; // untuk upload ke R2 tanpa auth header

  @override
  Future<PresignResult> presignUpload({
    required int circleId,
    required String filename,
    required String contentType,
    required int fileSize,
  }) async {
    final response = await _api.post(Endpoints.presignUpload, data: {
      'circle_id': circleId,
      'filename': filename,
      'content_type': contentType,
      'file_size': fileSize,
    });

    return PresignResult.fromJson(response.data);
  }

  @override
  Future<void> uploadToR2({
    required String presignedUrl,
    required Uint8List imageBytes,
    required String contentType,
    required Function(double) onProgress,
  }) async {
    await _rawDio.put(
      presignedUrl,
      data: Stream.fromIterable(imageBytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': imageBytes.length,
        },
      ),
      onSendProgress: (sent, total) {
        onProgress(sent / total);
      },
    );
  }

  @override
  Future<PostModel> finalizeUpload({
    required int circleId,
    required String objectKey,
    String? thumbnailKey,
  }) async {
    final response = await _api.post(Endpoints.finalizeUpload, data: {
      'circle_id': circleId,
      'object_key': objectKey,
      if (thumbnailKey != null) 'thumbnail_key': thumbnailKey,
    });

    return PostModel.fromJson(response.data['post']);
  }
}
```

---

## 5. Feed Repository

```dart
// lib/features/feed/data/feed_repository_impl.dart

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _api;

  @override
  Future<FeedResult> getFeed({
    required int circleId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _api.get(
      Endpoints.circlePosts(circleId),
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response.data;
    return FeedResult(
      posts: (data['posts'] as List).map((p) => PostModel.fromJson(p)).toList(),
      hasMore: data['has_more'],
      nextCursor: data['next_cursor'],
    );
  }
}
```

---

## 6. Models

```dart
// lib/shared/models/post_model.dart

class PostModel extends Equatable {
  final int id;
  final int circleId;
  final int userId;
  final String username;
  final String imageUrl;
  final String? thumbnailUrl;
  final Map<String, int> reactionCounts;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.reactionCounts,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      circleId: json['circle_id'],
      userId: json['user_id'],
      username: json['username'],
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  PostModel copyWith({Map<String, int>? reactionCounts}) {
    return PostModel(
      id: id,
      circleId: circleId,
      userId: userId,
      username: username,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, reactionCounts];
}
```

---

## 7. Error Handling

```dart
// lib/core/errors/exceptions.dart

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });
}

// Helper
ApiException _handleDioError(DioException e) {
  final statusCode = e.response?.statusCode ?? 0;
  final errorCode = e.response?.data?['error'] ?? 'unknown_error';
  final message = e.response?.data?['message'] ?? 'Something went wrong';

  return ApiException(
    code: errorCode,
    message: message,
    statusCode: statusCode,
  );
}
```

---

## 8. Secure Storage

```dart
// lib/core/storage/secure_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: accessToken),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.accessTokenKey, value: token);

  Future<void> clear() => _storage.deleteAll();
}
```
