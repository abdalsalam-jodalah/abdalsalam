import 'dart:ui';

import 'package:flutter/painting.dart';

import 'appearance_options.dart';

class AppRadius {
  static const double pillValue = 999;
  static const Map<CornerStyle, List<double>> _scales = <CornerStyle, List<double>>{
    CornerStyle.soft: <double>[10, 14, 18, 24],
    CornerStyle.round: <double>[12, 18, 24, 30],
    CornerStyle.extraRound: <double>[16, 22, 30, 38],
  };

  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppRadius._({required this.sm, required this.md, required this.lg, required this.xl});

  factory AppRadius.forCornerStyle(CornerStyle style) {
    final scale = _scales[style]!;
    return AppRadius._(sm: scale[0], md: scale[1], lg: scale[2], xl: scale[3]);
  }

  static final AppRadius round = AppRadius.forCornerStyle(CornerStyle.round);

  BorderRadius get smallBorder => BorderRadius.circular(sm);
  BorderRadius get mediumBorder => BorderRadius.circular(md);
  BorderRadius get largeBorder => BorderRadius.circular(lg);
  BorderRadius get extraLargeBorder => BorderRadius.circular(xl);
  BorderRadius get pillBorder => BorderRadius.circular(pillValue);

  AppRadius lerp(AppRadius other, double t) {
    return AppRadius._(
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}
