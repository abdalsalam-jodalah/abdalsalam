import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.lg, spacing.lg, spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineSmall),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
