import 'package:flutter/material.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    this.small = 8,
    this.medium = 16,
    this.large = 24,
    this.extraLarge = 32,
  });

  final double small;
  final double medium;
  final double large;
  final double extraLarge;

  @override
  AppSpacing copyWith({
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
  }) {
    return AppSpacing(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
    );
  }

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      small: lerpDouble(small, other.small, t),
      medium: lerpDouble(medium, other.medium, t),
      large: lerpDouble(large, other.large, t),
      extraLarge: lerpDouble(extraLarge, other.extraLarge, t),
    );
  }

  static double lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }
}
