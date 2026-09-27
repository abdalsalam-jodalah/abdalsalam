import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class LogLevelBadge extends StatelessWidget {
  static const double _backgroundOpacity = 0.2;
  static const double _borderOpacity = 0.5;

  final String level;
  final Color color;

  const LogLevelBadge({super.key, required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: tokens.spacing.xs / 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _backgroundOpacity),
        borderRadius: tokens.radius.smallBorder,
        border: Border.all(color: color.withValues(alpha: _borderOpacity)),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
