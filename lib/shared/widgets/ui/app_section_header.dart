import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const AppSectionHeader({super.key, required this.title, this.subtitle, this.action, this.padding});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.only(top: spacing.lg, bottom: spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
