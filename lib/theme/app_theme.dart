import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const radius = AppRadius();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.turquoise700,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.turquoise700,
      primaryContainer: AppColors.mint300,
      onPrimary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.darkGray,
      error: AppColors.coral700,
      onError: AppColors.white,
    );

    final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme(base.textTheme).apply(
        bodyColor: AppColors.darkGray,
        displayColor: AppColors.darkGray,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.field),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.field),
          borderSide: const BorderSide(color: AppColors.mediumGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.field),
          borderSide: const BorderSide(
            color: AppColors.turquoise700,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.field),
          borderSide: const BorderSide(color: AppColors.coral700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.field),
          borderSide: const BorderSide(color: AppColors.coral700, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoise700,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.card),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColorTokens.standard(),
        AppSpacing(),
        radius,
      ],
    );
  }
}
