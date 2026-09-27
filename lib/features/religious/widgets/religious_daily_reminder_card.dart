import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

const List<({String arabic, String translation})> _dailyReminders = [
  (arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', translation: 'Glory be to Allah and praise Him'),
  (arabic: 'الحَمْدُ لِلَّهِ', translation: 'All praise is due to Allah'),
  (arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ', translation: 'There is no god but Allah'),
  (arabic: 'اللَّهُ أَكْبَرُ', translation: 'Allah is the Greatest'),
  (arabic: 'أَسْتَغْفِرُ اللَّهَ', translation: 'I seek forgiveness from Allah'),
  (arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', translation: 'There is no power except with Allah'),
  (arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', translation: 'Allah is sufficient for us, and He is the best disposer of affairs'),
];

class ReligiousDailyReminderCard extends StatelessWidget {
  static const double _arabicLineHeight = 1.6;

  const ReligiousDailyReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final reminder = _dailyReminders[dayOfYear % _dailyReminders.length];

    return AppCard(
      accentColor: theme.colorScheme.tertiary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: Icons.auto_awesome, color: theme.colorScheme.tertiary),
          SizedBox(width: tokens.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge?.copyWith(height: _arabicLineHeight),
                ),
                SizedBox(height: tokens.spacing.xs),
                Text(
                  reminder.translation,
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
