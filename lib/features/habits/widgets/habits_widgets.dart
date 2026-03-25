import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  final String title;
  final VoidCallback? onCheckIn;

  const HabitCard({super.key, required this.title, this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onCheckIn,
        ),
      ),
    );
  }
}

class CompletionCalendar extends StatelessWidget {
  final Map<DateTime, bool> entries;

  const CompletionCalendar({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Completion days: ${entries.length}'),
      ),
    );
  }
}

class MoodTrendChart extends StatelessWidget {
  final List<double> values;

  const MoodTrendChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Mood samples: ${values.length}'),
      ),
    );
  }
}

class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.local_fire_department, size: 18),
      label: Text('$streak day streak'),
    );
  }
}
