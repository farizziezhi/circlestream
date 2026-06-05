library circlestream.features.realtime.bloc.realtime_bloc;

import 'dart:async';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/post_model.dart';
import '../../feed/bloc/feed_bloc.dart';
import '../../feed/bloc/feed_event.dart';
import '../../reaction/widgets/floating_emoji_animation.dart';
import '../services/ably_service.dart';
import 'realtime_event.dart';
import 'realtime_state.dart';

class RealtimeBloc extends Bloc<RealtimeEvent, RealtimeState> {
  final AblyService _ablyService;
  final FeedBloc _feedBloc;
  final ApiClient _apiClient;
  
  StreamSubscription? _eventSubscription;
  StreamSubscription? _connectionSubscription;
  bool _wasConnectedOnce = false;
  int? _circleId;

  RealtimeBloc({
    required AblyService ablyService,
    required FeedBloc feedBloc,
    required ApiClient apiClient,
  })  : _ablyService = ablyService,
        _feedBloc = feedBloc,
        _apiClient = apiClient,
        super(const RealtimeDisconnected()) {
    on<ConnectRealtimeEvent>(_onConnect);
    on<DisconnectRealtimeEvent>(_onDisconnect);
    on<AblyMessageReceivedEvent>(_onMessageReceived);
  }

  Future<void> _onConnect(
      ConnectRealtimeEvent event, Emitter<RealtimeState> emit) async {
    emit(const RealtimeConnecting());
    _circleId = event.circleId;
    _wasConnectedOnce = false;

    try {
      // Listen for connection changes to detect reconnection
      _connectionSubscription?.cancel();
      _connectionSubscription = _ablyService.connectionStateChanges.listen((stateChange) {
        if (stateChange.current == ably.ConnectionState.connected) {
          if (_wasConnectedOnce && _circleId != null) {
            _feedBloc.add(RefreshFeedEvent(circleId: _circleId!));
          } else {
            _wasConnectedOnce = true;
          }
        }
      });

      await _ablyService.connect(
        circleId: event.circleId,
        apiClient: _apiClient,
      );

      _eventSubscription?.cancel();
      _eventSubscription = _ablyService.events.listen((data) {
        add(AblyMessageReceivedEvent(data: data));
      });

      emit(RealtimeConnected(circleId: event.circleId));
    } catch (e) {
      emit(RealtimeError(error: e.toString()));
    }
  }

  Future<void> _onDisconnect(
      DisconnectRealtimeEvent event, Emitter<RealtimeState> emit) async {
    await _eventSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _ablyService.disconnect();
    _circleId = null;
    emit(const RealtimeDisconnected());
  }

  void _onMessageReceived(
      AblyMessageReceivedEvent event, Emitter<RealtimeState> emit) {
    final type = event.data['type'] as String?;
    
    switch (type) {
      case 'post_created':
        try {
          final post = PostModel.fromJson(event.data['post'] as Map<String, dynamic>);
          _feedBloc.add(NewPostReceivedEvent(post: post));
        } catch (e) {
          debugPrint('Error parsing post_created event: $e');
        }
        break;
      case 'reaction_added':
        final postId = event.data['post_id'] as int?;
        final emoji = event.data['emoji'] as String?;
        final count = event.data['count'] as int?;
        if (postId != null && emoji != null && count != null) {
          _feedBloc.add(ReactionUpdateReceivedEvent(
            postId: postId,
            emoji: emoji,
            count: count,
          ));
          // Trigger floating animation
          FloatingEmojiController.instance.trigger(emoji);
        }
        break;
      case 'member_joined':
        final user = event.data['user'] as Map<String, dynamic>?;
        final username = user?['username'] as String? ?? 'Seseorang';
        debugPrint('$username telah bergabung ke circle.');
        break;
      case 'member_left':
        final user = event.data['user'] as Map<String, dynamic>?;
        final username = user?['username'] as String? ?? 'Seseorang';
        debugPrint('$username telah keluar dari circle.');
        break;
    }
  }

  @override
  Future<void> close() async {
    await _eventSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _ablyService.disconnect();
    return super.close();
  }
}
