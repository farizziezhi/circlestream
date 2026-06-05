library circlestream.features.circle.bloc.circle_event;

import 'package:equatable/equatable.dart';

abstract class CircleEvent extends Equatable {
  const CircleEvent();

  @override
  List<Object?> get props => [];
}

class LoadCirclesEvent extends CircleEvent {
  const LoadCirclesEvent();
}

class CreateCircleEvent extends CircleEvent {
  final String name;

  const CreateCircleEvent({required this.name});

  @override
  List<Object?> get props => [name];
}

class JoinCircleEvent extends CircleEvent {
  final String inviteCode;

  const JoinCircleEvent({required this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

class LoadCircleDetailEvent extends CircleEvent {
  final int circleId;

  const LoadCircleDetailEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class LoadMembersEvent extends CircleEvent {
  final int circleId;

  const LoadMembersEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class LeaveCircleEvent extends CircleEvent {
  final int circleId;

  const LeaveCircleEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class LoadInviteCodesEvent extends CircleEvent {
  final int circleId;

  const LoadInviteCodesEvent({required this.circleId});

  @override
  List<Object?> get props => [circleId];
}

class GenerateInviteCodeEvent extends CircleEvent {
  final int circleId;
  final int? maxUses;

  const GenerateInviteCodeEvent({required this.circleId, this.maxUses});

  @override
  List<Object?> get props => [circleId, maxUses];
}
