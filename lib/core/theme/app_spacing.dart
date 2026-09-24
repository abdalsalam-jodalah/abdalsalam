import 'dart:ui';

import 'appearance_options.dart';

class AppSpacing {
  static const double _comfortableScale = 1;
  static const double _compactScale = 0.8;

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  const AppSpacing._({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  factory AppSpacing.forDensity(DensityOption density) {
    final scale = density == DensityOption.compact ? _compactScale : _comfortableScale;
    return AppSpacing._(
      xs: 4 * scale,
      sm: 8 * scale,
      md: 12 * scale,
      lg: 16 * scale,
      xl: 24 * scale,
      xxl: 32 * scale,
    );
  }

  static final AppSpacing comfortable = AppSpacing.forDensity(DensityOption.comfortable);

  AppSpacing lerp(AppSpacing other, double t) {
    return AppSpacing._(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
    );
  }
}
