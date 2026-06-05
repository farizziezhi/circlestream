library circlestream.features.feed.data.feed_repository;

import '../../../shared/models/post_model.dart';

class FeedResult {
  final List<PostModel> posts;
  final bool hasMore;
  final String? nextCursor;

  const FeedResult({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
  });

  factory FeedResult.fromJson(Map<String, dynamic> json) {
    return FeedResult(
      posts: (json['posts'] as List?)
              ?.map((p) => PostModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      hasMore: json['has_more'] as bool? ?? false,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}

abstract class FeedRepository {
  Future<FeedResult> getFeed(
    int circleId, {
    String? cursor,
    int limit = 20,
  });

  Future<PostModel> getPost(int postId);
}
