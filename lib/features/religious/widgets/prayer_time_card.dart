import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class PrayerTimeCard extends StatelessWidget {
  static const double _width = 84;
  static const double _iconSize = 18;
  static const double _mutedOpacity = 0.85;
  static const double _inactiveTintOpacity = 0.4;

  final String prayerName;
  final DateTime time;
  final bool isNext;
  final bool isPast;

  const PrayerTimeCard({
    super.key,
    required this.prayerName,
    required this.time,
    this.isNext = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = isNext ? scheme.onPrimary : scheme.onSurface;
    final muted = isNext ? scheme.onPrimary.withValues(alpha: _mutedOpacity) : scheme.onSurfaceVariant;
    final contentColor = isPast && !isNext ? muted : foreground;

    return Container(
      width: _width,
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.md, horizontal: tokens.spacing.sm),
      decoration: BoxDecoration(
        color: isNext ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: _inactiveTintOpacity),
        borderRadius: tokens.radius.largeBorder,
        border: isNext ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNext ? Icons.notifications_active_outlined : Icons.access_time,
            size: _iconSize,
            color: contentColor,
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            prayerName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: contentColor,
              fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          SizedBox(height: tokens.spacing.xs / 2),
          Text(
            TimeOfDay.fromDateTime(time).format(context),
            style: theme.textTheme.bodySmall?.copyWith(color: contentColor),
          ),
        ],
      ),
    );
  }
}
