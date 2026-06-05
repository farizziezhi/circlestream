library circlestream.features.reaction.bloc.reaction_bloc;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feed/bloc/feed_bloc.dart';
import '../../feed/bloc/feed_state.dart';
import '../data/reaction_repository.dart';
import '../widgets/floating_emoji_animation.dart';
import 'reaction_event.dart';
import 'reaction_state.dart';

class ReactionBloc extends Bloc<ReactionEvent, ReactionState> {
  final ReactionRepository _reactionRepository;
  final FeedBloc _feedBloc;
  final Map<int, Map<String, int>> _reactionsCache = {};

  ReactionBloc({
    required ReactionRepository reactionRepository,
    required FeedBloc feedBloc,
  })  : _reactionRepository = reactionRepository,
        _feedBloc = feedBloc,
        super(const ReactionInitial()) {
    on<AddReactionEvent>(_onAddReaction);
    on<GetReactionsEvent>(_onGetReactions);
  }

  Future<void> _onAddReaction(
      AddReactionEvent event, Emitter<ReactionState> emit) async {
    // 1. Determine current count (from FeedBloc state or local cache)
    int currentCount = 0;
    final feedState = _feedBloc.state;
    if (feedState is FeedLoaded) {
      try {
        final post = feedState.posts.firstWhere((p) => p.id == event.postId);
        currentCount = post.reactionCounts[event.emoji] ?? 0;
      } catch (_) {
        currentCount = _reactionsCache[event.postId]?[event.emoji] ?? 0;
      }
    } else {
      currentCount = _reactionsCache[event.postId]?[event.emoji] ?? 0;
    }

    // Update local cache optimistically
    final Map<String, int> cachedReactions = Map.from(_reactionsCache[event.postId] ?? {});
    cachedReactions[event.emoji] = currentCount + 1;
    _reactionsCache[event.postId] = cachedReactions;

    // Emit optimistic count+1
    emit(ReactionUpdated(
      postId: event.postId,
      emoji: event.emoji,
      count: currentCount + 1,
    ));

    try {
      // 2. Call repository to add reaction on backend
      final result = await _reactionRepository.addReaction(
        postId: event.postId,
        emoji: event.emoji,
      );

      // Update local cache with actual count
      final Map<String, int> updatedReactions = Map.from(_reactionsCache[event.postId] ?? {});
      updatedReactions[event.emoji] = result.count;
      _reactionsCache[event.postId] = updatedReactions;

      // 3. Emit success with actual count
      emit(ReactionUpdated(
        postId: event.postId,
        emoji: event.emoji,
        count: result.count,
      ));

      // 4. Trigger floating emoji animation
      FloatingEmojiController.instance.trigger(event.emoji);
    } catch (e) {
      // Revert optimistic count on failure
      final Map<String, int> revertedReactions = Map.from(_reactionsCache[event.postId] ?? {});
      revertedReactions[event.emoji] = currentCount;
      _reactionsCache[event.postId] = revertedReactions;

      emit(ReactionUpdated(
        postId: event.postId,
        emoji: event.emoji,
        count: currentCount,
      ));

      emit(ReactionError(error: _mapError(e)));
    }
  }

  Future<void> _onGetReactions(
      GetReactionsEvent event, Emitter<ReactionState> emit) async {
    emit(const ReactionLoading());
    try {
      final reactions = await _reactionRepository.getReactions(
        postId: event.postId,
      );
      _reactionsCache[event.postId] = reactions;
      emit(ReactionLoaded(
        postId: event.postId,
        reactions: reactions,
      ));
    } catch (e) {
      emit(ReactionError(error: _mapError(e)));
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final res = error.response;
      if (res != null && res.data is Map) {
        final errCode = res.data['error'] as String?;
        switch (errCode) {
          case 'invalid_emoji':
            return 'Emoji tidak valid';
          case 'not_member':
            return 'Kamu bukan member circle ini';
        }
      }
    }
    return 'Gagal mengirim reaction';
  }
}
