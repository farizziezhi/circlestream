library circlestream.shared.models.user_model;

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String username;
  final String email;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, username, email, createdAt];
}
