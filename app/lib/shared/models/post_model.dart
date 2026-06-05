library circlestream.shared.models.post_model;

import 'package:equatable/equatable.dart';

class PostModel extends Equatable {
  final int id;
  final int circleId;
  final int userId;
  final String username;
  final String imageUrl;
  final String? thumbnailUrl;
  final Map<String, int> reactionCounts;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.username,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.reactionCounts,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      circleId: json['circle_id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      imageUrl: json['image_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      reactionCounts: Map<String, int>.from(json['reaction_counts'] ?? {}),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'user_id': userId,
      'username': username,
      'image_url': imageUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      'reaction_counts': reactionCounts,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PostModel copyWith({
    int? id,
    int? circleId,
    int? userId,
    String? username,
    String? imageUrl,
    String? thumbnailUrl,
    Map<String, int>? reactionCounts,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        circleId,
        userId,
        username,
        imageUrl,
        thumbnailUrl,
        reactionCounts,
        createdAt,
      ];
}
