// lib/features/religious/widgets/prayer_streak_widget.dart
import 'package:flutter/material.dart';

class PrayerStreakWidget extends StatelessWidget {
  final int streakDays;

  const PrayerStreakWidget({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.orange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streakDays == 0 ? 'No streak yet' : '$streakDays day${streakDays == 1 ? '' : 's'} streak',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakDays == 0
                        ? 'Log a prayer today to start one'
                        : 'Keep praying on time to grow it',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
