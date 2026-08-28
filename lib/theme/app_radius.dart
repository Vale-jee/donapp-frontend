import 'package:flutter/material.dart';

@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  const AppRadius({
    this.field = 12,
    this.button = 12,
    this.card = 16,
    this.featuredCard = 20,
  });

  final double field;
  final double button;
  final double card;
  final double featuredCard;

  @override
  AppRadius copyWith({
    double? field,
    double? button,
    double? card,
    double? featuredCard,
  }) {
    return AppRadius(
      field: field ?? this.field,
      button: button ?? this.button,
      card: card ?? this.card,
      featuredCard: featuredCard ?? this.featuredCard,
    );
  }

  @override
  AppRadius lerp(covariant AppRadius? other, double t) {
    if (other == null) return this;
    return AppRadius(
      field: _lerpDouble(field, other.field, t),
      button: _lerpDouble(button, other.button, t),
      card: _lerpDouble(card, other.card, t),
      featuredCard: _lerpDouble(featuredCard, other.featuredCard, t),
    );
  }

  static double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }
}
