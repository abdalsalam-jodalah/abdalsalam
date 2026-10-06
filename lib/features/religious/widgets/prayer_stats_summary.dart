import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';

class PrayerStatsSummary extends StatelessWidget {
  static const int _percentScale = 100;

  final List<PrayerLog> allLogs;

  const PrayerStatsSummary({super.key, required this.allLogs});

  @override
  Widget build(BuildContext context) {
    final obligatoryLogs = allLogs.where((log) => log.prayerName.isObligatory).toList(growable: false);
    final voluntaryCount = allLogs.length - obligatoryLogs.length;
    final onTimeCount = obligatoryLogs.where((log) => log.onTime).length;
    final onTimePercent = obligatoryLogs.isEmpty ? 0 : ((onTimeCount / obligatoryLogs.length) * _percentScale).round();
    final accent = AppModuleAccents.forModule('religious');

    return StatGrid(
      children: [
        StatTile(
          icon: Icons.mosque_rounded,
          label: 'Total Logs',
          value: '${obligatoryLogs.length}',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'On Time',
          value: '$onTimePercent%',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.volunteer_activism_rounded,
          label: 'For God',
          value: '$voluntaryCount',
          accentColor: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }
}
