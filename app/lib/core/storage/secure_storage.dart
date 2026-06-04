library circlestream.core.storage.secure_storage;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

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

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.userIdKey);

  Future<void> saveUserId(String id) =>
      _storage.write(key: AppConstants.userIdKey, value: id);

  Future<void> clear() => _storage.deleteAll();
}
