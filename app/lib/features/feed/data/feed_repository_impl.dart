library circlestream.features.feed.data.feed_repository_impl;

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/models/post_model.dart';
import 'feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _apiClient;

  FeedRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<FeedResult> getFeed(
    int circleId, {
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      Endpoints.circlePosts(circleId),
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    return FeedResult.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PostModel> getPost(int postId) async {
    final response = await _apiClient.get(Endpoints.postDetail(postId));
    final data = response.data as Map<String, dynamic>;
    return PostModel.fromJson(data['post'] as Map<String, dynamic>);
  }
}
