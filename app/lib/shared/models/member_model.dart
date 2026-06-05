library circlestream.shared.models.member_model;

import 'package:equatable/equatable.dart';

class MemberModel extends Equatable {
  final int userId;
  final String username;
  final String role;
  final DateTime? joinedAt;

  const MemberModel({
    required this.userId,
    required this.username,
    required this.role,
    this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'role': role,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, username, role, joinedAt];
}
