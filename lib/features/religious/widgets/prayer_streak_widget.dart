import 'package:flutter/material.dart';

class PrayerStreakWidget extends StatelessWidget {
  final int streakDays;

  const PrayerStreakWidget({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Current streak: $streakDays days'),
          ],
        ),
      ),
    );
  }
}
