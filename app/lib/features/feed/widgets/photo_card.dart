library circlestream.features.feed.widgets.photo_card;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../reaction/bloc/reaction_bloc.dart';
import '../../reaction/bloc/reaction_event.dart';
import '../../reaction/bloc/reaction_state.dart';
import '../../reaction/widgets/emoji_reaction_bar.dart';

class PhotoCard extends StatefulWidget {
  final PostModel post;

  const PhotoCard({
    super.key,
    required this.post,
  });

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  late Map<String, int> _localReactionCounts;

  @override
  void initState() {
    super.initState();
    _localReactionCounts = Map<String, int>.from(widget.post.reactionCounts);
  }

  @override
  void didUpdateWidget(PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.reactionCounts != oldWidget.post.reactionCounts) {
      _localReactionCounts = Map<String, int>.from(widget.post.reactionCounts);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReactionBloc, ReactionState>(
      listenWhen: (previous, current) {
        return (current is ReactionUpdated && current.postId == widget.post.id) ||
            (current is ReactionLoaded && current.postId == widget.post.id);
      },
      listener: (context, state) {
        if (state is ReactionUpdated) {
          setState(() {
            _localReactionCounts = Map<String, int>.from(_localReactionCounts);
            _localReactionCounts[state.emoji] = state.count;
          });
        } else if (state is ReactionLoaded) {
          setState(() {
            _localReactionCounts = Map<String, int>.from(state.reactions);
          });
        }
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image container with rounded top corners
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              child: GestureDetector(
                onTap: () {
                  context.push('/feed/post/${widget.post.id}', extra: widget.post);
                },
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedImage(
                    imageUrl: widget.post.imageUrl,
                    borderRadius: 0,
                  ),
                ),
              ),
            ),

            // Card body details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username avatar & time relative info
                  Row(
                    children: [
                      AvatarWidget(
                        username: widget.post.username,
                        size: 32,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.username,
                              style: GoogleFonts.dmSans(
                                textStyle: AppTextStyles.labelMedium,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getRelativeTime(widget.post.createdAt),
                              style: GoogleFonts.dmSans(
                                textStyle: AppTextStyles.caption,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // React emoji bar
                  EmojiReactionBar(
                    counts: _localReactionCounts,
                    onReact: (emoji) {
                      context.read<ReactionBloc>().add(
                            AddReactionEvent(
                              postId: widget.post.id,
                              emoji: emoji,
                            ),
                          );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
