# Real-time Integration

## CircleStream — Flutter + Ably Integration Guide

---

## 1. Overview

Flutter terhubung ke Ably menggunakan **token authentication** (bukan API key langsung). Backend meng-generate token dengan capability terbatas untuk setiap user.

---

## 2. Ably Service

```dart
// lib/features/realtime/services/ably_service.dart

import 'package:ably_flutter/ably_flutter.dart' as ably;
import 'package:dio/dio.dart';

class AblyService {
  ably.Realtime? _client;
  ably.RealtimeChannel? _activeChannel;
  StreamController<Map<String, dynamic>>? _eventController;

  Stream<Map<String, dynamic>> get events =>
      _eventController!.stream.asBroadcastStream();

  Future<void> connect({required int circleId, required ApiClient api}) async {
    _eventController = StreamController<Map<String, dynamic>>.broadcast();

    // 1. Fetch token dari backend
    final token = await _fetchAblyToken(api, circleId);

    // 2. Init Ably client dengan token
    final opts = ably.ClientOptions(
      authCallback: (params) async => token,
    );
    _client = ably.Realtime(options: opts);

    // 3. Monitor connection state
    _client!.connection.on().listen((stateChange) {
      if (stateChange.current == ably.ConnectionState.connected) {
        _subscribeToChannel(circleId);
      }
    });

    await _client!.connect();
  }

  Future<String> _fetchAblyToken(ApiClient api, int circleId) async {
    final response = await api.get('/ably/token', queryParameters: {
      'circle_id': circleId,
    });
    return response.data['token'];
  }

  void _subscribeToChannel(int circleId) {
    _activeChannel = _client!.channels.get('circle:$circleId');

    _activeChannel!.subscribe().listen((message) {
      try {
        final data = jsonDecode(message.data as String);
        _eventController?.add(data);
      } catch (e) {
        // Malformed event, ignore
      }
    });
  }

  Future<void> disconnect() async {
    await _activeChannel?.detach();
    await _client?.close();
    await _eventController?.close();
    _client = null;
    _activeChannel = null;
    _eventController = null;
  }

  // Reconnect handler — call setelah reconnect untuk sync state
  bool get isConnected =>
      _client?.connection.state == ably.ConnectionState.connected;
}
```

---

## 3. Realtime BLoC

```dart
// lib/features/realtime/bloc/realtime_bloc.dart

class RealtimeBloc extends Bloc<RealtimeEvent, RealtimeState> {
  final AblyService _ablyService;
  final FeedBloc _feedBloc;
  final CircleBloc _circleBloc;
  StreamSubscription? _eventSub;

  RealtimeBloc({
    required AblyService ablyService,
    required FeedBloc feedBloc,
    required CircleBloc circleBloc,
  })  : _ablyService = ablyService,
        _feedBloc = feedBloc,
        _circleBloc = circleBloc,
        super(RealtimeDisconnected()) {
    on<ConnectRealtimeEvent>(_onConnect);
    on<DisconnectRealtimeEvent>(_onDisconnect);
    on<AblyMessageReceivedEvent>(_onMessage);
  }

  Future<void> _onConnect(ConnectRealtimeEvent event, Emitter<RealtimeState> emit) async {
    emit(RealtimeConnecting());

    try {
      await _ablyService.connect(
        circleId: event.circleId,
        api: event.api,
      );

      _eventSub = _ablyService.events.listen((data) {
        add(AblyMessageReceivedEvent(data: data));
      });

      emit(RealtimeConnected(circleId: event.circleId));
    } catch (e) {
      emit(RealtimeError(error: e.toString()));
    }
  }

  Future<void> _onDisconnect(DisconnectRealtimeEvent event, Emitter<RealtimeState> emit) async {
    await _eventSub?.cancel();
    await _ablyService.disconnect();
    emit(RealtimeDisconnected());
  }

  void _onMessage(AblyMessageReceivedEvent event, Emitter<RealtimeState> emit) {
    final type = event.data['type'] as String?;

    switch (type) {
      case 'post_created':
        _handlePostCreated(event.data);
        break;
      case 'reaction_added':
        _handleReactionAdded(event.data);
        break;
      case 'member_joined':
        _handleMemberJoined(event.data);
        break;
      case 'member_left':
        _handleMemberLeft(event.data);
        break;
      case 'circle_updated':
        _handleCircleUpdated(event.data);
        break;
    }
  }

  void _handlePostCreated(Map<String, dynamic> data) {
    final post = PostModel.fromJson(data['post']);
    _feedBloc.add(NewPostReceivedEvent(post: post));
  }

  void _handleReactionAdded(Map<String, dynamic> data) {
    _feedBloc.add(ReactionUpdateReceivedEvent(
      postId: data['post_id'],
      emoji: data['emoji'],
      count: data['count'],
    ));
    // Trigger animation melalui global animation controller
    FloatingEmojiController.instance.trigger(data['emoji']);
  }

  void _handleMemberJoined(Map<String, dynamic> data) {
    _circleBloc.add(MemberJoinedEvent(data: data));
  }

  void _handleMemberLeft(Map<String, dynamic> data) {
    _circleBloc.add(MemberLeftEvent(data: data));
  }

  void _handleCircleUpdated(Map<String, dynamic> data) {
    _circleBloc.add(RefreshCircleEvent());
  }

  @override
  Future<void> close() async {
    await _eventSub?.cancel();
    await _ablyService.disconnect();
    return super.close();
  }
}
```

---

## 4. Floating Emoji Animation Widget

```dart
// lib/features/reaction/widgets/floating_emoji_animation.dart

class FloatingEmojiOverlay extends StatefulWidget {
  final Widget child;
  const FloatingEmojiOverlay({required this.child});

  @override
  State<FloatingEmojiOverlay> createState() => _FloatingEmojiOverlayState();
}

class _FloatingEmojiOverlayState extends State<FloatingEmojiOverlay> {
  final List<_EmojiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    FloatingEmojiController.instance.stream.listen((emoji) {
      _addParticle(emoji);
    });
  }

  void _addParticle(String emoji) {
    final random = Random();
    setState(() {
      _particles.add(_EmojiParticle(
        emoji: emoji,
        x: 0.2 + random.nextDouble() * 0.6, // 20%-80% width
        id: UniqueKey(),
      ));
    });

    // Remove setelah animasi selesai
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _particles.removeWhere((p) => p.id == _particles.last.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._particles.map((p) => _FloatingEmojiWidget(particle: p)),
      ],
    );
  }
}

class _FloatingEmojiWidget extends StatefulWidget {
  final _EmojiParticle particle;
  const _FloatingEmojiWidget({required this.particle});

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _positionAnim = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: MediaQuery.of(context).size.width * widget.particle.x,
          top: MediaQuery.of(context).size.height * _positionAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Text(
              widget.particle.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 5. Feed Screen — Ably Integration

```dart
// Di FeedScreen, connect Ably saat masuk dan disconnect saat keluar

class FeedScreen extends StatefulWidget { ... }

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Load feed
    context.read<FeedBloc>().add(LoadFeedEvent(circleId: widget.circleId));
    // Connect realtime
    context.read<RealtimeBloc>().add(ConnectRealtimeEvent(
      circleId: widget.circleId,
      api: sl<ApiClient>(),
    ));
  }

  @override
  void dispose() {
    context.read<RealtimeBloc>().add(DisconnectRealtimeEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingEmojiOverlay(
      child: BlocBuilder<FeedBloc, FeedState>(
        builder: (context, state) {
          if (state is FeedLoading) return const Center(child: CircularProgressIndicator());
          if (state is FeedLoaded) return _buildFeed(state.posts);
          return const SizedBox();
        },
      ),
    );
  }
}
```

---

## 6. Connection State Handling

```dart
// Tampilkan indicator saat offline

BlocBuilder<RealtimeBloc, RealtimeState>(
  builder: (context, state) {
    if (state is RealtimeDisconnected || state is RealtimeError) {
      return Container(
        color: Colors.orange.shade100,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: const Center(
          child: Text('Offline — pull to refresh', style: TextStyle(fontSize: 12)),
        ),
      );
    }
    return const SizedBox.shrink();
  },
)
```
