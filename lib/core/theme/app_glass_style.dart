import 'dart:ui';

import 'package:flutter/material.dart';

import 'appearance_options.dart';

class AppGlassStyle {
  static const double _lightTintOpacity = 0.68;
  static const double _darkTintOpacity = 0.46;
  static const double _lightBorderOpacity = 0.7;
  static const double _darkBorderOpacity = 0.12;
  static const double _blurSigma = 18;
  static const double _shadowBlur = 18;
  static const double _shadowOffsetY = 6;
  static const double _lightShadowOpacity = 0.05;
  static const double _darkShadowOpacity = 0.3;

  final bool isGlass;
  final Color surfaceTint;
  final Color borderColor;
  final double blurSigma;
  final List<BoxShadow> shadows;

  const AppGlassStyle({
    required this.isGlass,
    required this.surfaceTint,
    required this.borderColor,
    required this.blurSigma,
    required this.shadows,
  });

  factory AppGlassStyle.forScheme(ColorScheme scheme, SurfaceStyle style) {
    final isDark = scheme.brightness == Brightness.dark;
    final isGlass = style == SurfaceStyle.glass;
    final base = isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest;
    return AppGlassStyle(
      isGlass: isGlass,
      surfaceTint: isGlass ? base.withValues(alpha: isDark ? _darkTintOpacity : _lightTintOpacity) : base,
      borderColor: isDark
          ? Colors.white.withValues(alpha: _darkBorderOpacity)
          : Colors.white.withValues(alpha: isGlass ? _lightBorderOpacity : 0),
      blurSigma: isGlass ? _blurSigma : 0,
      shadows: <BoxShadow>[
        BoxShadow(
          color: scheme.shadow.withValues(alpha: isDark ? _darkShadowOpacity : _lightShadowOpacity),
          blurRadius: _shadowBlur,
          offset: const Offset(0, _shadowOffsetY),
        ),
      ],
    );
  }

  AppGlassStyle lerp(AppGlassStyle other, double t) {
    return AppGlassStyle(
      isGlass: t < 0.5 ? isGlass : other.isGlass,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? other.shadows,
    );
  }
}
