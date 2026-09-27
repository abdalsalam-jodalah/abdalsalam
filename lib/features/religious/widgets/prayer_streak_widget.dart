import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

class PrayerStreakWidget extends StatelessWidget {
  final int streakDays;

  const PrayerStreakWidget({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return AppCard(
      accentColor: tokens.colors.warning,
      child: Row(
        children: [
          IconBadge(icon: Icons.local_fire_department_rounded, color: tokens.colors.warning),
          SizedBox(width: tokens.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakDays == 0 ? 'No streak yet' : '$streakDays day${streakDays == 1 ? '' : 's'} streak',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: tokens.spacing.xs / 2),
                Text(
                  streakDays == 0 ? 'Log a prayer today to start one' : 'Keep praying on time to grow it',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
