library circlestream.shared.models.circle_model;

import 'package:equatable/equatable.dart';

class CircleModel extends Equatable {
  final int id;
  final String name;
  final int ownerId;
  final int memberCount;
  final DateTime? createdAt;

  const CircleModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.memberCount = 0,
    this.createdAt,
  });

  factory CircleModel.fromJson(Map<String, dynamic> json) {
    return CircleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerId: json['owner_id'] as int,
      memberCount: json['member_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  CircleModel copyWith({
    int? id,
    String? name,
    int? ownerId,
    int? memberCount,
    DateTime? createdAt,
  }) {
    return CircleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, memberCount, createdAt];
}
