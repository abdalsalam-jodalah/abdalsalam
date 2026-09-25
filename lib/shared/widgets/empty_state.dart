import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';
import 'ui/icon_badge.dart';

class EmptyState extends StatelessWidget {
  static const String _defaultActionLabel = 'Add Item';
  static const double _iconSize = 64;
  static const double _compactIconSize = 44;

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final bool isCompact;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel = _defaultActionLabel,
    this.onAction,
    this.icon = Icons.inbox_rounded,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? spacing.lg : spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(icon: icon, size: isCompact ? _compactIconSize : _iconSize),
            SizedBox(height: spacing.md),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            SizedBox(height: spacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onAction != null) ...[
              SizedBox(height: spacing.lg),
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
