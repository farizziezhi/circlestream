library circlestream.design.app_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(textStyle: AppTextStyles.displayLarge),
        headlineLarge: GoogleFonts.poppins(textStyle: AppTextStyles.h1),
        headlineMedium: GoogleFonts.poppins(textStyle: AppTextStyles.h2),
        headlineSmall: GoogleFonts.poppins(textStyle: AppTextStyles.h3),
        bodyLarge: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyLarge),
        bodyMedium: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyMedium),
        bodySmall: GoogleFonts.dmSans(textStyle: AppTextStyles.bodySmall),
        labelMedium: GoogleFonts.dmSans(textStyle: AppTextStyles.labelMedium),
        labelSmall: GoogleFonts.dmSans(textStyle: AppTextStyles.caption),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.dmSans(textStyle: AppTextStyles.labelMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
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
        labelStyle: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyMedium).copyWith(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.dmSans(textStyle: AppTextStyles.bodyMedium).copyWith(color: AppColors.textHint),
        errorStyle: GoogleFonts.dmSans(textStyle: AppTextStyles.bodySmall).copyWith(color: AppColors.error),
      ),
    );
  }
}
