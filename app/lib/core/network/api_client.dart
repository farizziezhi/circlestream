library circlestream.core.network.api_client;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient({required SecureStorage secureStorage}) {
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
      AuthInterceptor(secureStorage: secureStorage),
      if (kDebugMode)
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

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(path, data: data);
}
