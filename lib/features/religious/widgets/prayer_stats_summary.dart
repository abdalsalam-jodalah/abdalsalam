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
    final onTimeCount = allLogs.where((log) => log.onTime).length;
    final onTimePercent = allLogs.isEmpty ? 0 : ((onTimeCount / allLogs.length) * _percentScale).round();
    final accent = AppModuleAccents.forModule('religious');

    return StatGrid(
      children: [
        StatTile(
          icon: Icons.mosque_rounded,
          label: 'Total Logs',
          value: '${allLogs.length}',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'On Time',
          value: '$onTimePercent%',
          accentColor: accent,
        ),
      ],
    );
  }
}
