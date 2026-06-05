library circlestream.features.reaction.data.reaction_repository;

import 'package:equatable/equatable.dart';

abstract class ReactionRepository {
  Future<ReactionResult> addReaction({required int postId, required String emoji});
  Future<Map<String, int>> getReactions({required int postId});
}

class ReactionResult extends Equatable {
  final int postId;
  final String emoji;
  final int count;

  const ReactionResult({
    required this.postId,
    required this.emoji,
    required this.count,
  });

  factory ReactionResult.fromJson(Map<String, dynamic> json) {
    return ReactionResult(
      postId: json['post_id'] as int,
      emoji: json['emoji'] as String,
      count: json['count'] as int,
    );
  }

  @override
  List<Object?> get props => [postId, emoji, count];
}
