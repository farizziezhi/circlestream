library circlestream.features.realtime.bloc.realtime_event;

import 'package:equatable/equatable.dart';

abstract class RealtimeEvent extends Equatable {
  const RealtimeEvent();

  @override
  List<Object?> get props => [];
}

class ConnectRealtimeEvent extends RealtimeEvent {
  final int circleId;

  const ConnectRealtimeEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class DisconnectRealtimeEvent extends RealtimeEvent {
  const DisconnectRealtimeEvent();
}

class AblyMessageReceivedEvent extends RealtimeEvent {
  final Map<String, dynamic> data;

  const AblyMessageReceivedEvent({required this.data});

  @override
  List<Object?> get props => [data];
}
