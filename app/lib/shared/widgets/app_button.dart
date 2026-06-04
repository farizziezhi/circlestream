library circlestream.shared.widgets.app_button;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.96 : 1.0;
    
    final Color buttonColor = widget.isPrimary ? AppColors.primary : Colors.transparent;
    final Color textColor = widget.isPrimary ? Colors.white : AppColors.primary;
    final Border? border = widget.isPrimary ? null : Border.all(color: AppColors.primary, width: 2.0);

    final Widget buttonChild = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Text(
            widget.label,
            style: GoogleFonts.dmSans(
              textStyle: AppTextStyles.labelMedium,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          );

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: widget.isLoading || widget.onTap == null
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isLoading || widget.onTap == null
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              },
        onTapCancel: widget.isLoading || widget.onTap == null
            ? null
            : () => setState(() => _isPressed = false),
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: buttonColor,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.center,
          child: buttonChild,
        ),
      ),
    );
  }
}
