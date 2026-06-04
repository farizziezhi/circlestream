library circlestream.features.reaction.widgets.emoji_reaction_bar;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/constants.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radius.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';

class EmojiReactionBar extends StatelessWidget {
  final Map<String, int> counts;
  final Function(String emoji) onReact;

  const EmojiReactionBar({
    super.key,
    required this.counts,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: AppConstants.emojiPresets.map((emoji) {
          final int count = counts[emoji] ?? 0;
          final bool hasReacted = count > 0;

          return _EmojiButton(
            emoji: emoji,
            count: count,
            isActive: hasReacted,
            onTap: () => onReact(emoji),
          );
        }).toList(),
      ),
    );
  }
}

class _EmojiButton extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.count.toString(),
                  style: GoogleFonts.dmSans(
                    textStyle: AppTextStyles.bodySmall,
                    color: widget.isActive
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
