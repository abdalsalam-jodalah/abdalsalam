import 'package:flutter/material.dart';

import '../../../data/models/habits/habit.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/month_heatmap.dart';
import 'habit_style_picker.dart';

class HabitCard extends StatelessWidget {
  static const String _badHabitLabel = 'Bad habit';

  final Habit habit;
  final int currentStreak;
  final VoidCallback? onCheckIn;
  final VoidCallback? onTap;

  const HabitCard({
    super.key,
    required this.habit,
    required this.currentStreak,
    this.onCheckIn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = habitColorFromHex(habit.color);
    final icon = kHabitIconOptions[habit.icon] ?? kHabitIconOptions[kDefaultHabitIcon]!;
    return EntityTile(
      title: habit.name,
      subtitle: habit.isGoodHabit ? null : _badHabitLabel,
      icon: icon,
      accentColor: color,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakBadge(streak: currentStreak),
          IconButton(
            icon: Icon(habit.isGoodHabit ? Icons.check_circle_outline : Icons.edit_note_outlined),
            onPressed: onCheckIn,
          ),
        ],
      ),
    );
  }
}

class CompletionCalendar extends StatelessWidget {
  final Map<DateTime, bool> entries;
  final DateTime month;

  CompletionCalendar({super.key, required this.entries, DateTime? month}) : month = month ?? DateTime.now();

  double _intensityForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return entries[normalized] == true ? 1.0 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: MonthHeatmap(month: month, intensityForDay: _intensityForDay),
    );
  }
}

class MoodTrendChart extends StatelessWidget {
  static const String _noMoodDataMessage = 'No mood data logged yet';

  final List<double> values;

  const MoodTrendChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return AppCard(child: Text(_noMoodDataMessage, style: Theme.of(context).textTheme.bodyMedium));
    }
    return AppLineChart(points: values);
  }
}

class StreakBadge extends StatelessWidget {
  static const double _streakIconSize = 18;

  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.local_fire_department, size: _streakIconSize),
      label: Text('$streak day streak'),
    );
  }
}
