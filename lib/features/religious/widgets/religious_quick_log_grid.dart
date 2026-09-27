import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../screens/athkar_screen.dart';
import '../screens/bad_practice_screen.dart';
import '../screens/prayer_logs_screen.dart';
import '../screens/quran_reading_screen.dart';

class ReligiousQuickLogGrid extends StatelessWidget {
  static const int _crossAxisCount = 3;
  static const double _childAspectRatio = 1.1;

  final VoidCallback onNightPrayerTap;

  const ReligiousQuickLogGrid({super.key, required this.onNightPrayerTap});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: _crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: tokens.spacing.sm,
      mainAxisSpacing: tokens.spacing.sm,
      childAspectRatio: _childAspectRatio,
      children: [
        _QuickLogTile(
          label: 'Prayer',
          icon: Icons.mosque_rounded,
          color: scheme.primary,
          onTap: () => Navigator.of(context).pushNamed(PrayerLogsScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Quran',
          icon: Icons.menu_book_rounded,
          color: scheme.secondary,
          onTap: () => Navigator.of(context).pushNamed(QuranReadingScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Athkar',
          icon: Icons.favorite_rounded,
          color: scheme.tertiary,
          onTap: () => Navigator.of(context).pushNamed(AthkarScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Night Prayer',
          icon: Icons.nights_stay_rounded,
          color: scheme.primary,
          onTap: onNightPrayerTap,
        ),
        _QuickLogTile(
          label: 'Bad Event',
          icon: Icons.warning_amber_rounded,
          color: scheme.error,
          onTap: () => Navigator.of(context).pushNamed(BadPracticeScreen.routeName),
        ),
      ],
    );
  }
}

class _QuickLogTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(icon: icon, color: color),
          SizedBox(height: tokens.spacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
