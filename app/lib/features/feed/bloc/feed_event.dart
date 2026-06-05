library circlestream.features.feed.bloc.feed_event;

import 'package:equatable/equatable.dart';
import '../../../shared/models/post_model.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeedEvent extends FeedEvent {
  final int circleId;

  const LoadFeedEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class LoadMoreFeedEvent extends FeedEvent {
  const LoadMoreFeedEvent();
}

class RefreshFeedEvent extends FeedEvent {
  final int circleId;

  const RefreshFeedEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class NewPostReceivedEvent extends FeedEvent {
  final PostModel post;

  const NewPostReceivedEvent({required this.post});

  @override
  List<Object?> get props => [post];
}

class ReactionUpdateReceivedEvent extends FeedEvent {
  final int postId;
  final String emoji;
  final int count;

  const ReactionUpdateReceivedEvent({
    required this.postId,
    required this.emoji,
    required this.count,
  });

  @override
  List<Object?> get props => [postId, emoji, count];
}
