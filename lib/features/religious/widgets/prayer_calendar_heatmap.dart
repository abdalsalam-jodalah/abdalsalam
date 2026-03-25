import 'package:flutter/material.dart';

class PrayerCalendarHeatmap extends StatelessWidget {
  final Map<DateTime, int> dailyCompletions;

  const PrayerCalendarHeatmap({
    super.key,
    required this.dailyCompletions,
  });

  @override
  Widget build(BuildContext context) {
    final entries = dailyCompletions.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prayer completion heatmap'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entries.take(30).map((entry) {
                final intensity = (entry.value / 5).clamp(0, 1);
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2 + (0.8 * intensity)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
