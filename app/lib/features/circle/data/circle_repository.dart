library circlestream.features.circle.data.circle_repository;

import '../../../shared/models/circle_model.dart';
import '../../../shared/models/invite_code_model.dart';
import '../../../shared/models/member_model.dart';

class CircleCreateResult {
  final CircleModel circle;
  final InviteCodeModel inviteCode;

  const CircleCreateResult({
    required this.circle,
    required this.inviteCode,
  });
}

class JoinCircleResult {
  final CircleModel circle;
  final MemberModel member;

  const JoinCircleResult({
    required this.circle,
    required this.member,
  });
}

abstract class CircleRepository {
  Future<List<CircleModel>> getMyCircles();
  Future<CircleCreateResult> createCircle(String name);
  Future<JoinCircleResult> joinCircle(String inviteCode);
  Future<CircleModel> getCircle(int circleId);
  Future<List<MemberModel>> getMembers(int circleId);
  Future<void> leaveCircle(int circleId);
  Future<List<InviteCodeModel>> getInviteCodes(int circleId);
  Future<InviteCodeModel> generateInviteCode(int circleId, {int? maxUses});
}
