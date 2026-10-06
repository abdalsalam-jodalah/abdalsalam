import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class PrayerLogTile extends StatelessWidget {
  static const String _voluntaryLabel = 'Voluntary';

  final PrayerLog log;

  const PrayerLogTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVoluntary = log.prayerName.isVoluntary;
    return EntityTile(
      icon: isVoluntary ? Icons.volunteer_activism_rounded : Icons.mosque_rounded,
      accentColor: isVoluntary ? scheme.tertiary : scheme.primary,
      title: '${log.prayerName.label.toUpperCase()} • ${AppDateFormatter.shortDate(log.prayedAt)}',
      subtitle: '${AppDateFormatter.time(log.prayedAt)}'
          '${isVoluntary ? ' • $_voluntaryLabel' : ''}'
          '${log.scheduledAt != null ? ' • ${_deltaLabel(log)}' : ''}',
      trailing: isVoluntary
          ? Icon(Icons.favorite_rounded, color: scheme.tertiary)
          : Icon(
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
        ? '$minutes min before ${log.prayerName.label}'
        : '$minutes min after ${log.prayerName.label}';
  }
}
