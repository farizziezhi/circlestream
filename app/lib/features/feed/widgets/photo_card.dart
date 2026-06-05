library circlestream.features.feed.widgets.photo_card;

import 'package:flutter/material.dart';
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
import '../../reaction/widgets/emoji_reaction_bar.dart';

class PhotoCard extends StatelessWidget {
  final PostModel post;
  final Function(String emoji) onReact;

  const PhotoCard({
    super.key,
    required this.post,
    required this.onReact,
  });

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
    return AppCard(
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
                context.push('/feed/post/${post.id}', extra: post);
              },
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedImage(
                  imageUrl: post.imageUrl,
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
                      username: post.username,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: GoogleFonts.dmSans(
                              textStyle: AppTextStyles.labelMedium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getRelativeTime(post.createdAt),
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
                  counts: post.reactionCounts,
                  onReact: onReact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
