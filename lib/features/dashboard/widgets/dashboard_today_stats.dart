import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../../planning/providers/planning_providers.dart';
import '../../religious/providers/prayer_providers.dart';
import '../../religious/providers/quran_providers.dart';

class DashboardTodayStats extends ConsumerWidget {
  static const int dailyPrayerCount = 5;
  static const String _pendingValue = '—';

  const DashboardTodayStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerCount = ref.watch(prayerCountProvider);
    final quranPages = ref.watch(quranPagesTodayProvider);
    final goals = ref.watch(todaysGoalsProvider);
    return StatGrid(
      children: [
        StatTile(
          icon: Icons.mosque_rounded,
          label: 'Prayers today',
          value: '$prayerCount / $dailyPrayerCount',
          accentColor: AppModuleAccents.forModule('religious'),
        ),
        StatTile(
          icon: Icons.menu_book_rounded,
          label: 'Quran pages',
          value: '$quranPages',
          accentColor: AppModuleAccents.forModule('religious'),
        ),
        StatTile(
          icon: Icons.flag_rounded,
          label: 'Goals today',
          value: goals.maybeWhen(data: (items) => '${items.length}', orElse: () => _pendingValue),
          accentColor: AppModuleAccents.forModule('planning'),
        ),
      ],
    );
  }
}
