import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'app_card.dart';
import 'icon_badge.dart';

class EntityTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final Color? accentColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int subtitleMaxLines;

  const EntityTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.accentColor,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.subtitleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final theme = Theme.of(context);
    final leadingWidget = leading ?? (icon == null ? null : IconBadge(icon: icon!, color: accentColor));
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          if (leadingWidget != null) ...[leadingWidget, SizedBox(width: spacing.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: subtitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: spacing.sm), trailing!],
        ],
      ),
    );
  }
}
