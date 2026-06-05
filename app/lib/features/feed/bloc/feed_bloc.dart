library circlestream.features.feed.bloc.feed_bloc;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/feed_repository.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepository;

  FeedBloc({required FeedRepository feedRepository})
      : _feedRepository = feedRepository,
        super(const FeedInitial()) {
    on<LoadFeedEvent>(_onLoadFeed);
    on<LoadMoreFeedEvent>(_onLoadMoreFeed);
    on<RefreshFeedEvent>(_onRefreshFeed);
    on<NewPostReceivedEvent>(_onNewPostReceived);
    on<ReactionUpdateReceivedEvent>(_onReactionUpdateReceived);
  }

  Future<void> _onLoadFeed(LoadFeedEvent event, Emitter<FeedState> emit) async {
    emit(const FeedLoading());
    try {
      final result = await _feedRepository.getFeed(event.circleId);
      emit(FeedLoaded(
        posts: result.posts,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        circleId: event.circleId,
      ));
    } catch (e) {
      emit(FeedError(error: e.toString()));
    }
  }

  Future<void> _onLoadMoreFeed(
      LoadMoreFeedEvent event, Emitter<FeedState> emit) async {
    final currentState = state;
    if (currentState is FeedLoaded &&
        currentState.hasMore &&
        currentState.nextCursor != null) {
      try {
        final result = await _feedRepository.getFeed(
          currentState.circleId,
          cursor: currentState.nextCursor,
        );
        emit(FeedLoaded(
          posts: [...currentState.posts, ...result.posts],
          hasMore: result.hasMore,
          nextCursor: result.nextCursor,
          circleId: currentState.circleId,
        ));
      } catch (e) {
        emit(FeedError(error: e.toString()));
      }
    }
  }

  Future<void> _onRefreshFeed(
      RefreshFeedEvent event, Emitter<FeedState> emit) async {
    try {
      final result = await _feedRepository.getFeed(event.circleId);
      emit(FeedLoaded(
        posts: result.posts,
        hasMore: result.hasMore,
        nextCursor: result.nextCursor,
        circleId: event.circleId,
      ));
    } catch (e) {
      emit(FeedError(error: e.toString()));
    }
  }

  void _onNewPostReceived(
      NewPostReceivedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      if (event.post.circleId == currentState.circleId) {
        if (!currentState.posts.any((p) => p.id == event.post.id)) {
          emit(FeedLoaded(
            posts: [event.post, ...currentState.posts],
            hasMore: currentState.hasMore,
            nextCursor: currentState.nextCursor,
            circleId: currentState.circleId,
          ));
        }
      }
    }
  }

  void _onReactionUpdateReceived(
      ReactionUpdateReceivedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          final newReactions = Map<String, int>.from(post.reactionCounts);
          newReactions[event.emoji] = event.count;
          return post.copyWith(reactionCounts: newReactions);
        }
        return post;
      }).toList();

      emit(FeedLoaded(
        posts: updatedPosts,
        hasMore: currentState.hasMore,
        nextCursor: currentState.nextCursor,
        circleId: currentState.circleId,
      ));
    }
  }
}
