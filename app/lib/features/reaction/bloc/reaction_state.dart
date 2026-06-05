library circlestream.features.reaction.bloc.reaction_state;

import 'package:equatable/equatable.dart';

abstract class ReactionState extends Equatable {
  const ReactionState();

  @override
  List<Object?> get props => [];
}

class ReactionInitial extends ReactionState {
  const ReactionInitial();
}

class ReactionLoading extends ReactionState {
  const ReactionLoading();
}

class ReactionUpdated extends ReactionState {
  final int postId;
  final String emoji;
  final int count;

  const ReactionUpdated({
    required this.postId,
    required this.emoji,
    required this.count,
  });

  @override
  List<Object?> get props => [postId, emoji, count];
}

class ReactionLoaded extends ReactionState {
  final int postId;
  final Map<String, int> reactions;

  const ReactionLoaded({
    required this.postId,
    required this.reactions,
  });

  @override
  List<Object?> get props => [postId, reactions];
}

class ReactionError extends ReactionState {
  final String error;

  const ReactionError({
    required this.error,
  });

  @override
  List<Object?> get props => [error];
}
