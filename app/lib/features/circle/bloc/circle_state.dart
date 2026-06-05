library circlestream.features.circle.bloc.circle_state;

import 'package:equatable/equatable.dart';
import '../../../shared/models/circle_model.dart';
import '../../../shared/models/invite_code_model.dart';
import '../../../shared/models/member_model.dart';
import '../data/circle_repository.dart';

abstract class CircleState extends Equatable {
  const CircleState();

  @override
  List<Object?> get props => [];
}

class CircleInitial extends CircleState {}

class CircleLoading extends CircleState {}

class CircleListLoaded extends CircleState {
  final List<CircleModel> circles;

  const CircleListLoaded({required this.circles});

  @override
  List<Object?> get props => [circles];
}

class CircleDetailLoaded extends CircleState {
  final CircleModel circle;

  const CircleDetailLoaded({required this.circle});

  @override
  List<Object?> get props => [circle];
}

class CircleMembersLoaded extends CircleState {
  final List<MemberModel> members;

  const CircleMembersLoaded({required this.members});

  @override
  List<Object?> get props => [members];
}

class CircleInviteCodesLoaded extends CircleState {
  final List<InviteCodeModel> inviteCodes;

  const CircleInviteCodesLoaded({required this.inviteCodes});

  @override
  List<Object?> get props => [inviteCodes];
}

class CircleCreated extends CircleState {
  final CircleCreateResult result;

  const CircleCreated({required this.result});

  @override
  List<Object?> get props => [result.circle, result.inviteCode];
}

class CircleJoined extends CircleState {
  final JoinCircleResult result;

  const CircleJoined({required this.result});

  @override
  List<Object?> get props => [result.circle];
}

class CircleLeft extends CircleState {}

class CircleInviteCodeGenerated extends CircleState {
  final InviteCodeModel inviteCode;

  const CircleInviteCodeGenerated({required this.inviteCode});

  @override
  List<Object?> get props => [inviteCode];
}

class CircleError extends CircleState {
  final String error;

  const CircleError({required this.error});

  @override
  List<Object?> get props => [error];
}
