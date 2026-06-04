library circlestream.features.auth.data.auth_repository_impl;

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepositoryImpl({
    required ApiClient apiClient,
    required SecureStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  @override
  Future<AuthResult> login(String email, String password) async {
    final response = await _apiClient.post(
      Endpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['tokens']['access_token'] as String;
    final refreshToken = data['tokens']['refresh_token'] as String;

    // Persist session details locally
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storage.saveUserId(user.id.toString());
    await _storage.saveUser(user);

    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<AuthResult> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await _apiClient.post(
      Endpoints.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['tokens']['access_token'] as String;
    final refreshToken = data['tokens']['refresh_token'] as String;

    // Persist session details locally
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storage.saveUserId(user.id.toString());
    await _storage.saveUser(user);

    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _apiClient.post(
        Endpoints.logout,
        data: {
          'refresh_token': refreshToken,
        },
      );
    } finally {
      // Always clear local secure storage on logout, even if API call fails
      await _storage.clear();
    }
  }

  @override
  Future<String> refreshToken(String token) async {
    final response = await _apiClient.post(
      Endpoints.refresh,
      data: {
        'refresh_token': token,
      },
    );

    final newAccessToken = response.data['access_token'] as String;
    await _storage.saveAccessToken(newAccessToken);
    return newAccessToken;
  }
}
