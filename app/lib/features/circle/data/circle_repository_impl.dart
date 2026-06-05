library circlestream.features.circle.data.circle_repository_impl;

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/models/circle_model.dart';
import '../../../shared/models/invite_code_model.dart';
import '../../../shared/models/member_model.dart';
import 'circle_repository.dart';

class CircleRepositoryImpl implements CircleRepository {
  final ApiClient _apiClient;

  CircleRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<CircleModel>> getMyCircles() async {
    final response = await _apiClient.get(Endpoints.circles);
    final data = response.data as Map<String, dynamic>;
    final circles = (data['circles'] as List<dynamic>?) ?? [];
    return circles
        .map((json) => CircleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CircleCreateResult> createCircle(String name) async {
    final response = await _apiClient.post(
      Endpoints.circles,
      data: {'name': name},
    );
    final data = response.data as Map<String, dynamic>;
    return CircleCreateResult(
      circle: CircleModel.fromJson(data['circle'] as Map<String, dynamic>),
      inviteCode:
          InviteCodeModel.fromJson(data['invite_code'] as Map<String, dynamic>),
    );
  }

  @override
  Future<JoinCircleResult> joinCircle(String inviteCode) async {
    final response = await _apiClient.post(
      Endpoints.joinCircle,
      data: {'invite_code': inviteCode},
    );
    final data = response.data as Map<String, dynamic>;
    final circleJson = data['circle'] as Map<String, dynamic>;
    final memberJson = data['member'] as Map<String, dynamic>;
    return JoinCircleResult(
      circle: CircleModel(
        id: circleJson['id'] as int,
        name: circleJson['name'] as String,
        ownerId: 0, // Not provided by join response
        memberCount: circleJson['member_count'] as int? ?? 0,
      ),
      member: MemberModel(
        userId: memberJson['user_id'] as int,
        username: '', // Not provided by join response
        role: memberJson['role'] as String,
        joinedAt: memberJson['joined_at'] != null
            ? DateTime.parse(memberJson['joined_at'] as String)
            : null,
      ),
    );
  }

  @override
  Future<CircleModel> getCircle(int circleId) async {
    final response = await _apiClient.get(Endpoints.circleDetail(circleId));
    final data = response.data as Map<String, dynamic>;
    return CircleModel.fromJson(data['circle'] as Map<String, dynamic>);
  }

  @override
  Future<List<MemberModel>> getMembers(int circleId) async {
    final response = await _apiClient.get(Endpoints.circleMembers(circleId));
    final data = response.data as Map<String, dynamic>;
    final members = (data['members'] as List<dynamic>?) ?? [];
    return members
        .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> leaveCircle(int circleId) async {
    await _apiClient.post(Endpoints.leaveCircle(circleId));
  }

  @override
  Future<List<InviteCodeModel>> getInviteCodes(int circleId) async {
    final response = await _apiClient.get(Endpoints.inviteCodes(circleId));
    final data = response.data as Map<String, dynamic>;
    final codes = (data['invite_codes'] as List<dynamic>?) ?? [];
    return codes
        .map((json) => InviteCodeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InviteCodeModel> generateInviteCode(int circleId,
      {int? maxUses}) async {
    final response = await _apiClient.post(
      Endpoints.inviteCodes(circleId),
      data: {'max_uses': maxUses},
    );
    final data = response.data as Map<String, dynamic>;
    return InviteCodeModel.fromJson(
        data['invite_code'] as Map<String, dynamic>);
  }
}
