library circlestream.features.feed.bloc.feed_state;

import 'package:equatable/equatable.dart';
import '../../../shared/models/post_model.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<PostModel> posts;
  final bool hasMore;
  final String? nextCursor;
  final int circleId;

  const FeedLoaded({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
    required this.circleId,
  });

  @override
  List<Object?> get props => [posts, hasMore, nextCursor, circleId];
}

class FeedError extends FeedState {
  final String error;

  const FeedError({required this.error});

  @override
  List<Object?> get props => [error];
}
