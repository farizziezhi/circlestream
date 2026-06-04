library circlestream.features.auth.data.auth_repository;

import '../../../shared/models/user_model.dart';

class AuthResult {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String username, String email, String password);
  Future<void> logout(String refreshToken);
  Future<String> refreshToken(String token);
}
