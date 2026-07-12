// lib/features/religious/widgets/prayer_calendar_heatmap.dart
import 'package:flutter/material.dart';

class PrayerCalendarHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyCompletions;
  static const int _prayersPerDay = 5;

  const PrayerCalendarHeatmap({
    super.key,
    required this.dailyCompletions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 29));

    final days = List<DateTime>.generate(30, (i) => startDay.add(Duration(days: i)));
    final leadingBlanks = (startDay.weekday % 7);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prayer completion', style: Theme.of(context).textTheme.titleMedium),
                Text('Last 30 days', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              children: [
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (final day in days)
                  Tooltip(
                    message: '${day.month}/${day.day}: ${dailyCompletions[day] ?? 0}/$_prayersPerDay',
                    child: _HeatCell(
                      intensity: ((dailyCompletions[day] ?? 0) / _prayersPerDay).clamp(0, 1).toDouble(),
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Less', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(width: 6),
                for (final level in [0.0, 0.25, 0.5, 0.75, 1.0])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _HeatCell(intensity: level, color: scheme.primary, size: 12),
                  ),
                const SizedBox(width: 6),
                Text('More', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  final double intensity;
  final Color color;
  final double size;

  const _HeatCell({required this.intensity, required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: intensity == 0
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : color.withValues(alpha: 0.2 + (0.8 * intensity)),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
