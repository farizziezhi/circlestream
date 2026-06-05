library circlestream.features.realtime.bloc.realtime_state;

import 'package:equatable/equatable.dart';

abstract class RealtimeState extends Equatable {
  const RealtimeState();

  @override
  List<Object?> get props => [];
}

class RealtimeDisconnected extends RealtimeState {
  const RealtimeDisconnected();
}

class RealtimeConnecting extends RealtimeState {
  const RealtimeConnecting();
}

class RealtimeConnected extends RealtimeState {
  final int circleId;

  const RealtimeConnected({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class RealtimeError extends RealtimeState {
  final String error;

  const RealtimeError({required this.error});

  @override
  List<Object?> get props => [error];
}
