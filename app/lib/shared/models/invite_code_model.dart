library circlestream.shared.models.invite_code_model;

import 'package:equatable/equatable.dart';

class InviteCodeModel extends Equatable {
  final int id;
  final String code;
  final bool isActive;
  final int? maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const InviteCodeModel({
    required this.id,
    required this.code,
    required this.isActive,
    this.maxUses,
    this.usedCount = 0,
    this.expiresAt,
    this.createdAt,
  });

  bool get isSingleUse => maxUses == 1;
  bool get isMultiUse => maxUses == null || maxUses! > 1;

  factory InviteCodeModel.fromJson(Map<String, dynamic> json) {
    return InviteCodeModel(
      id: json['id'] as int,
      code: json['code'] as String,
      isActive: json['is_active'] as bool,
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'is_active': isActive,
      'max_uses': maxUses,
      'used_count': usedCount,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, code, isActive, maxUses, usedCount, expiresAt, createdAt];
}
