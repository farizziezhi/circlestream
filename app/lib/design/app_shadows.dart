library circlestream.design.app_shadows;

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  // Soft neumorphic shadow
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.shadowDark.withValues(alpha: 0.6),
      offset: const Offset(4, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.shadowLight.withValues(alpha: 0.9),
      offset: const Offset(-4, -4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Card shadow
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.shadowDark.withValues(alpha: 0.4),
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Floating / elevated
  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
}
