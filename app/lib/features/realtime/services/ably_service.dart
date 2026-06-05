library circlestream.features.realtime.services.ably_service;

import 'dart:async';
import 'dart:convert';
import 'package:ably_flutter/ably_flutter.dart' as ably;
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class AblyService {
  ably.Realtime? _client;
  ably.RealtimeChannel? _activeChannel;
  StreamController<Map<String, dynamic>>? _eventController;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _channelSubscription;

  final StreamController<ably.ConnectionStateChange> _connectionStateController =
      StreamController<ably.ConnectionStateChange>.broadcast();

  Stream<Map<String, dynamic>> get events {
    if (_eventController == null) {
      _eventController = StreamController<Map<String, dynamic>>.broadcast();
    }
    return _eventController!.stream;
  }

  Stream<ably.ConnectionStateChange> get connectionStateChanges =>
      _connectionStateController.stream;

  bool get isConnected =>
      _client?.connection.state == ably.ConnectionState.connected;

  Future<void> connect({
    required int circleId,
    required ApiClient apiClient,
  }) async {
    await disconnect();

    _eventController = StreamController<Map<String, dynamic>>.broadcast();

    // 1. Fetch token from backend
    final token = await _fetchAblyToken(apiClient, circleId);

    // 2. Init Ably client with token
    final opts = ably.ClientOptions(
      authCallback: (params) async => token,
    );
    _client = ably.Realtime(options: opts);

    // 3. Monitor connection state
    _connectionSubscription = _client!.connection.on().listen((stateChange) {
      _connectionStateController.add(stateChange);
      if (stateChange.current == ably.ConnectionState.connected) {
        _subscribeToChannel(circleId);
      }
    });

    await _client!.connect();
  }

  Future<String> _fetchAblyToken(ApiClient api, int circleId) async {
    final response = await api.get(
      Endpoints.ablyToken,
      queryParameters: {'circle_id': circleId},
    );
    final data = response.data as Map<String, dynamic>;
    return data['token'] as String;
  }

  void _subscribeToChannel(int circleId) {
    if (_client == null) return;
    _activeChannel = _client!.channels.get('circle:$circleId');

    _channelSubscription?.cancel();
    _channelSubscription = _activeChannel!.subscribe().listen((message) {
      try {
        final data = jsonDecode(message.data as String) as Map<String, dynamic>;
        _eventController?.add(data);
      } catch (_) {
        // Ignore malformed payloads
      }
    });
  }

  Future<void> disconnect() async {
    _connectionSubscription?.cancel();
    _channelSubscription?.cancel();
    
    if (_activeChannel != null) {
      try {
        await _activeChannel!.detach();
      } catch (_) {}
    }
    if (_client != null) {
      try {
        await _client!.close();
      } catch (_) {}
    }
    
    _eventController?.close();
    _eventController = null;
    _client = null;
    _activeChannel = null;
  }
}
