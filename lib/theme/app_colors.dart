import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primitive colors.
  static const turquoise500 = Color(0xFF16B5A6);
  static const turquoise700 = Color(0xFF0F766E);
  static const turquoise800 = Color(0xFF0B5D56);

  static const mint300 = Color(0xFF7FDCC7);
  static const mint50 = Color(0xFFE6FAF4);

  static const coral500 = Color(0xFFFF6B6B);
  static const coral700 = Color(0xFFC24141);

  static const yellow400 = Color(0xFFFFD166);
  static const blue500 = Color(0xFF4DA3E8);
  static const beige500 = Color(0xFFB98B5E);

  static const darkGray = Color(0xFF1F2937);
  static const mediumGray = Color(0xFF6B7280);
  static const white = Color(0xFFFFFFFF);

  // Semantic colors not represented directly by the Material ColorScheme.
  static const background = mint50;
  static const textSecondary = mediumGray;
  static const accentCoral = coral500;
  static const accentYellow = yellow400;
  static const accentBlue = blue500;
}

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.background,
    required this.textSecondary,
    required this.accentCoral,
    required this.accentYellow,
    required this.accentBlue,
  });

  const AppColorTokens.standard()
    : background = AppColors.background,
      textSecondary = AppColors.textSecondary,
      accentCoral = AppColors.accentCoral,
      accentYellow = AppColors.accentYellow,
      accentBlue = AppColors.accentBlue;

  final Color background;
  final Color textSecondary;
  final Color accentCoral;
  final Color accentYellow;
  final Color accentBlue;

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? textSecondary,
    Color? accentCoral,
    Color? accentYellow,
    Color? accentBlue,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      textSecondary: textSecondary ?? this.textSecondary,
      accentCoral: accentCoral ?? this.accentCoral,
      accentYellow: accentYellow ?? this.accentYellow,
      accentBlue: accentBlue ?? this.accentBlue,
    );
  }

  @override
  AppColorTokens lerp(covariant AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accentCoral: Color.lerp(accentCoral, other.accentCoral, t)!,
      accentYellow: Color.lerp(accentYellow, other.accentYellow, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
    );
  }
}
