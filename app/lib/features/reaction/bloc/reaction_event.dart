library circlestream.features.reaction.bloc.reaction_event;

import 'package:equatable/equatable.dart';

abstract class ReactionEvent extends Equatable {
  const ReactionEvent();

  @override
  List<Object?> get props => [];
}

class AddReactionEvent extends ReactionEvent {
  final int postId;
  final String emoji;

  const AddReactionEvent({
    required this.postId,
    required this.emoji,
  });

  @override
  List<Object?> get props => [postId, emoji];
}

class GetReactionsEvent extends ReactionEvent {
  final int postId;

  const GetReactionsEvent({
    required this.postId,
  });

  @override
  List<Object?> get props => [postId];
}
