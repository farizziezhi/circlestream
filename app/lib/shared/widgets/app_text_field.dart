library circlestream.shared.widgets.app_text_field;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';
import '../../design/app_radius.dart';
import '../../design/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final Widget? suffixIcon = widget.obscureText
        ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            textStyle: AppTextStyles.labelMedium,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: GoogleFonts.dmSans(
            textStyle: AppTextStyles.bodyMedium,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.dmSans(
              textStyle: AppTextStyles.bodyMedium,
              color: AppColors.textHint,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 4.0),
          Text(
            widget.errorText!,
            style: GoogleFonts.dmSans(
              textStyle: AppTextStyles.bodySmall,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
