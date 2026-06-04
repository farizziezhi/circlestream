library circlestream.features.auth.bloc.auth_bloc;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  late final StreamSubscription _logoutSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage,
        super(AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<TokenExpiredEvent>(_onTokenExpired);

    // Listen to background token refresh failures from the AuthInterceptor
    _logoutSubscription = authLogoutController.stream.listen((_) {
      add(TokenExpiredEvent());
    });
  }

  @override
  Future<void> close() {
    _logoutSubscription.cancel();
    return super.close();
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    final token = await _secureStorage.getAccessToken();
    final user = await _secureStorage.getUser();
    if (token != null && user != null) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(error: _mapDioError(e)));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.register(
        event.username,
        event.email,
        event.password,
      );
      emit(AuthAuthenticated(user: result.user));
    } catch (e) {
      emit(AuthError(error: _mapDioError(e)));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _authRepository.logout(refreshToken);
      }
    } catch (_) {
      // Ignore API errors during logout to guarantee clean local state
    } finally {
      await _secureStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onTokenExpired(TokenExpiredEvent event, Emitter<AuthState> emit) async {
    await _secureStorage.clear();
    emit(AuthUnauthenticated());
  }

  String _mapDioError(Object error) {
    if (error is DioException) {
      final res = error.response;
      if (res != null && res.data is Map) {
        final errCode = res.data['error'] as String?;
        switch (errCode) {
          case 'invalid_credentials':
            return 'Email atau password salah';
          case 'email_taken':
            return 'Email sudah digunakan';
          case 'username_taken':
            return 'Username sudah digunakan';
          case 'validation_error':
            return 'Periksa kembali data yang kamu masukkan';
        }
      }
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
