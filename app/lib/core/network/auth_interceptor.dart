library circlestream.core.network.auth_interceptor;

import 'dart:async';
import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../storage/secure_storage.dart';

// Global stream to announce token expiration / failed refresh to the AuthBloc
final StreamController<void> authLogoutController = StreamController<void>.broadcast();

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  bool _isRefreshing = false;

  AuthInterceptor({required SecureStorage secureStorage})
      : _storage = secureStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final String path = options.path;
    // Skip attaching auth header for authentication endpoints
    if (path.endsWith('/auth/login') || 
        path.endsWith('/auth/register') || 
        path.endsWith('/auth/refresh')) {
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
        if (refreshToken == null) throw Exception('No refresh token available');

        // Call standard refresh endpoint with separate Dio client to avoid interceptor recursion
        final response = await Dio().post(
          '${AppConstants.baseUrl}/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newToken = response.data['access_token'] as String;
        await _storage.saveAccessToken(newToken);

        // Retry original request with the new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final responseOpts = err.requestOptions;
        
        final retriedResponse = await Dio().fetch(responseOpts);
        return handler.resolve(retriedResponse);
      } catch (_) {
        // Refresh failed (invalid/expired refresh token) -> clear credentials and broadcast logout
        await _storage.clear();
        authLogoutController.add(null);
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
