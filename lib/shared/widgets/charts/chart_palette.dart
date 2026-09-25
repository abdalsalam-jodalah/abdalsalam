import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class ChartPalette {
  const ChartPalette._();

  static List<Color> of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = AppThemeTokens.of(context).colors;
    return <Color>[
      scheme.primary,
      scheme.tertiary,
      colors.success,
      colors.warning,
      colors.info,
      colors.danger,
      scheme.secondary,
    ];
  }
}
