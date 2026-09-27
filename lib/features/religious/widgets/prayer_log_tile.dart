import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class PrayerLogTile extends StatelessWidget {
  final PrayerLog log;

  const PrayerLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return EntityTile(
      icon: Icons.mosque_rounded,
      accentColor: scheme.primary,
      title: '${log.prayerName.name.toUpperCase()} • ${AppDateFormatter.shortDate(log.prayedAt)}',
      subtitle: '${AppDateFormatter.time(log.prayedAt)}'
          '${log.scheduledAt != null ? ' • ${_deltaLabel(log)}' : ''}',
      trailing: Icon(
        log.onTime ? Icons.check_circle_rounded : Icons.schedule_rounded,
        color: log.onTime ? scheme.primary : scheme.tertiary,
      ),
    );
  }

  static String _deltaLabel(PrayerLog log) {
    final delta = log.prayedAt.difference(log.scheduledAt!);
    if (delta.inMinutes.abs() < 1) {
      return 'On time';
    }
    final minutes = delta.inMinutes.abs();
    return delta.isNegative
        ? '$minutes min before ${_prayerLabel(log.prayerName)}'
        : '$minutes min after ${_prayerLabel(log.prayerName)}';
  }

  static String _prayerLabel(PrayerName prayer) {
    return switch (prayer) {
      PrayerName.fajr => 'Fajr',
      PrayerName.dhuhr => 'Dhuhr',
      PrayerName.asr => 'Asr',
      PrayerName.maghrib => 'Maghrib',
      PrayerName.isha => 'Isha',
    };
  }
}
