library circlestream.features.auth.bloc.auth_state;

import 'package:equatable/equatable.dart';
import '../../../shared/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String error;

  const AuthError({required this.error});

  @override
  List<Object?> get props => [error];
}
