import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class DevInfoRow extends StatelessWidget {
  static const double _badgeBackgroundOpacity = 0.2;
  static const double _badgeBorderOpacity = 0.5;
  static const double _verticalPaddingFactor = 0.5;

  final String label;
  final String value;
  final Color accentColor;

  const DevInfoRow({super.key, required this.label, required this.value, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.sm,
              vertical: tokens.spacing.xs * _verticalPaddingFactor,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: _badgeBackgroundOpacity),
              borderRadius: tokens.radius.smallBorder,
              border: Border.all(color: accentColor.withValues(alpha: _badgeBorderOpacity)),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
