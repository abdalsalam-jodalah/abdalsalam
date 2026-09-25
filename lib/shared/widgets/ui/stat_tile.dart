import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'app_card.dart';
import 'icon_badge.dart';

class StatTile extends StatelessWidget {
  static const double _iconBadgeSize = 36;

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? accentColor;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(spacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, color: accentColor, size: _iconBadgeSize),
          SizedBox(height: spacing.sm),
          Text(
            value,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null)
            Text(
              caption!,
              style: theme.textTheme.labelSmall?.copyWith(color: accentColor ?? theme.colorScheme.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
