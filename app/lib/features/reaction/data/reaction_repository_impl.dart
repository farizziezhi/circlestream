library circlestream.features.reaction.data.reaction_repository_impl;

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import 'reaction_repository.dart';

class ReactionRepositoryImpl implements ReactionRepository {
  final ApiClient _apiClient;

  ReactionRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ReactionResult> addReaction({required int postId, required String emoji}) async {
    final response = await _apiClient.post(
      Endpoints.postReactions(postId),
      data: {'emoji': emoji},
    );
    return ReactionResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, int>> getReactions({required int postId}) async {
    final response = await _apiClient.get(Endpoints.postReactions(postId));
    final data = response.data as Map<String, dynamic>;
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    return reactionsData.map((key, value) => MapEntry(key, value as int));
  }
}
