import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const double mainTitleSize = 24;
  static const double sectionTitleSize = 20;
  static const double subtitleSize = 18;
  static const double bodySize = 16;
  static const double secondarySize = 14;
  static const double smallSize = 12;

  static const FontWeight titleWeight = FontWeight.w700;
  static const FontWeight subtitleWeight = FontWeight.w600;
  static const FontWeight bodyWeight = FontWeight.w400;

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: mainTitleSize,
        fontWeight: titleWeight,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: sectionTitleSize,
        fontWeight: titleWeight,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: sectionTitleSize,
        fontWeight: titleWeight,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: subtitleSize,
        fontWeight: subtitleWeight,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: bodySize,
        fontWeight: bodyWeight,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: secondarySize,
        fontWeight: bodyWeight,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: smallSize,
        fontWeight: bodyWeight,
      ),
    );
  }
}
