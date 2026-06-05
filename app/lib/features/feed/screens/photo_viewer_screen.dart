library circlestream.features.feed.screens.photo_viewer_screen;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../reaction/widgets/floating_emoji_animation.dart';
import '../../realtime/bloc/realtime_bloc.dart';
import '../../realtime/bloc/realtime_state.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../data/feed_repository.dart';
import '../widgets/photo_card.dart';
import '../../reaction/widgets/emoji_reaction_bar.dart';

class PhotoViewerScreen extends StatefulWidget {
  final String postId;
  final PostModel? post;

  const PhotoViewerScreen({
    super.key,
    required this.postId,
    this.post,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  PostModel? _post;
  bool _isLoading = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post;
    } else {
      _fetchPost();
    }
  }

  Future<void> _fetchPost() async {
    setState(() => _isLoading = true);
    try {
      final parsedId = int.parse(widget.postId);
      final post = await sl<FeedRepository>().getPost(parsedId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  Future<void> _react(String emoji, PostModel currentPost) async {
    final currentCount = currentPost.reactionCounts[emoji] ?? 0;
    // 1. Optimistic Update directly in FeedBloc
    context.read<FeedBloc>().add(
          ReactionUpdateReceivedEvent(
            postId: currentPost.id,
            emoji: emoji,
            count: currentCount + 1,
          ),
        );
    // Trigger local floating animation instantly
    FloatingEmojiController.instance.trigger(emoji);

    try {
      // 2. Call backend reaction endpoint
      final response = await sl<ApiClient>().post(
        Endpoints.postReactions(currentPost.id),
        data: {'emoji': emoji},
      );
      // 3. Update with the actual count from the server response
      final data = response.data as Map<String, dynamic>;
      final actualCount = data['count'] as int;
      context.read<FeedBloc>().add(
            ReactionUpdateReceivedEvent(
              postId: currentPost.id,
              emoji: emoji,
              count: actualCount,
            ),
          );
    } catch (_) {
      // Revert optimistic update on failure
      context.read<FeedBloc>().add(
            ReactionUpdateReceivedEvent(
              postId: currentPost.id,
              emoji: emoji,
              count: currentCount,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedId = int.parse(widget.postId);

    return FloatingEmojiOverlay(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : BlocBuilder<FeedBloc, FeedState>(
                builder: (context, state) {
                  PostModel? currentPost = _post;
                  if (state is FeedLoaded) {
                    final match = state.posts.firstWhere(
                      (p) => p.id == parsedId,
                      orElse: () => currentPost!,
                    );
                    currentPost = match;
                  }

                  if (currentPost == null) {
                    return const Center(
                      child: Text(
                        'Foto tidak ditemukan',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Pinch to Zoom + Swipe-down-to-dismiss gesture wrapper
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          if (details.primaryDelta! > 0) {
                            setState(() {
                              _dragOffset += details.primaryDelta!;
                            });
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (_dragOffset > 150.0) {
                            context.pop();
                          } else {
                            setState(() {
                              _dragOffset = 0.0;
                            });
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(0, _dragOffset),
                          child: InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Center(
                              child: CachedNetworkImage(
                                imageUrl: currentPost.imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) =>
                                    const AppLoadingIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Row Action (Close button)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                        left: AppSpacing.md,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        ),
                      ),

                      // Bottom Metadata & Reaction overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            top: AppSpacing.lg,
                            bottom: MediaQuery.of(context).padding.bottom +
                                AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Username row
                              Row(
                                children: [
                                  AvatarWidget(
                                    username: currentPost.username,
                                    size: 36,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentPost.username,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          _getRelativeTime(
                                              currentPost.createdAt),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Reaction Bar
                              EmojiReactionBar(
                                counts: currentPost.reactionCounts,
                                onReact: (emoji) => _react(emoji, currentPost!),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
