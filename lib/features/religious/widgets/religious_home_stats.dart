import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/athkar_providers.dart';
import '../providers/prayer_providers.dart';
import '../providers/quran_reading_providers.dart';

class ReligiousHomeStats extends ConsumerWidget {
  static const String _pendingValue = '…';

  const ReligiousHomeStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(religiousStreakProvider);
    final prayersToday = ref.watch(prayerCountProvider);
    final athkarToday = ref.watch(athkarTodayCountProvider);
    final quranPagesWeek = ref.watch(quranPagesThisWeekProvider);
    final accent = AppModuleAccents.forModule('religious');
    final tokens = AppThemeTokens.of(context);

    return StatGrid(
      children: [
        StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Streak',
          value: streak.maybeWhen(data: (v) => '$v d', orElse: () => _pendingValue),
          accentColor: tokens.colors.warning,
        ),
        StatTile(
          icon: Icons.mosque_rounded,
          label: 'Prayers Today',
          value: '$prayersToday',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.favorite_rounded,
          label: 'Athkar Today',
          value: '$athkarToday',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.menu_book_rounded,
          label: 'Quran (wk)',
          value: quranPagesWeek.maybeWhen(data: (v) => '$v p', orElse: () => _pendingValue),
          accentColor: accent,
        ),
      ],
    );
  }
}
