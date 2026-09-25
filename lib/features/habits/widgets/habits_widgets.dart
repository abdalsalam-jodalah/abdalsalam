import 'package:flutter/material.dart';

import '../../../data/models/habits/habit.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import 'habit_style_picker.dart';

class HabitCard extends StatelessWidget {
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
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color)),
        title: Text(habit.name),
        subtitle: !habit.isGoodHabit
            ? const Chip(
                visualDensity: VisualDensity.compact,
                label: Text('Bad habit'),
                backgroundColor: Color(0xFFFFEBEE),
              )
            : null,
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
      ),
    );
  }
}

class CompletionCalendar extends StatelessWidget {
  final Map<DateTime, bool> entries;
  final DateTime month;

  CompletionCalendar({super.key, required this.entries, DateTime? month}) : month = month ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: daysInMonth,
          itemBuilder: (context, index) {
            final day = index + 1;
            final date = DateTime(month.year, month.month, day);
            final logged = entries[date];
            final Color background;
            if (logged == true) {
              background = theme.colorScheme.primary;
            } else if (logged == false) {
              background = theme.colorScheme.errorContainer;
            } else {
              background = theme.colorScheme.surfaceContainerHighest;
            }
            return Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    color: logged == true ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MoodTrendChart extends StatelessWidget {
  final List<double> values;

  const MoodTrendChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(12), child: Text('No mood data logged yet')),
      );
    }
    return AppLineChart(points: values);
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
