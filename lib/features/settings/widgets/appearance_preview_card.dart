import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class AppearancePreviewCard extends StatelessWidget {
  static const String _title = 'Preview';
  static const String _statLabel = 'Prayers today';
  static const String _statValue = '4 / 5';
  static const String _chipLabel = 'On track';
  static const String _buttonLabel = 'Log';
  static const double _progressValue = 0.8;

  const AppearancePreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            SizedBox(height: tokens.spacing.md),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(tokens.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: tokens.radius.mediumBorder,
                  ),
                  child: Icon(Icons.mosque_rounded, color: theme.colorScheme.onPrimaryContainer),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_statLabel, style: theme.textTheme.bodySmall),
                      Text(_statValue, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                Chip(
                  label: const Text(_chipLabel),
                  avatar: Icon(Icons.check_circle_rounded, color: tokens.colors.success),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.md),
            const LinearProgressIndicator(value: _progressValue),
            SizedBox(height: tokens.spacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text(_buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
