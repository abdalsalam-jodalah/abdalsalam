import 'package:flutter/material.dart';

import 'app_glass_style.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';

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

  static AppThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    assert(tokens != null, 'AppThemeTokens missing: build the theme with buildAppTheme');
    return tokens!;
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
