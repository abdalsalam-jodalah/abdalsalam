import 'package:flutter/material.dart';

import 'app_glass_style.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'appearance_options.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final AppSpacing spacing;
  final AppRadius radius;
  final AppSemanticColors colors;
  final AppGlassStyle glass;
  final List<Color> backgroundGradient;

  const AppThemeTokens({
    required this.spacing,
    required this.radius,
    required this.colors,
    required this.glass,
    required this.backgroundGradient,
  });

  factory AppThemeTokens.fromScheme(
    ColorScheme scheme, {
    DensityOption density = DensityOption.comfortable,
    CornerStyle cornerStyle = CornerStyle.round,
    SurfaceStyle surfaceStyle = SurfaceStyle.glass,
    required List<Color> backgroundGradient,
  }) {
    return AppThemeTokens(
      spacing: AppSpacing.forDensity(density),
      radius: AppRadius.forCornerStyle(cornerStyle),
      colors: AppSemanticColors.forScheme(scheme),
      glass: AppGlassStyle.forScheme(scheme, surfaceStyle),
      backgroundGradient: backgroundGradient,
    );
  }

  static AppThemeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppThemeTokens>() ??
        AppThemeTokens.fromScheme(
          theme.colorScheme,
          surfaceStyle: SurfaceStyle.solid,
          backgroundGradient: <Color>[theme.colorScheme.surface, theme.colorScheme.surface, theme.colorScheme.surface],
        );
  }

  @override
  AppThemeTokens copyWith({
    AppSpacing? spacing,
    AppRadius? radius,
    AppSemanticColors? colors,
    AppGlassStyle? glass,
    List<Color>? backgroundGradient,
  }) {
    return AppThemeTokens(
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      colors: colors ?? this.colors,
      glass: glass ?? this.glass,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }
    return AppThemeTokens(
      spacing: spacing.lerp(other.spacing, t),
      radius: radius.lerp(other.radius, t),
      colors: colors.lerp(other.colors, t),
      glass: glass.lerp(other.glass, t),
      backgroundGradient: <Color>[
        for (var i = 0; i < backgroundGradient.length; i++)
          Color.lerp(backgroundGradient[i], other.backgroundGradient[i], t)!,
      ],
    );
  }
}
