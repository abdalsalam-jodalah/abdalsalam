import 'package:flutter/material.dart';

import '../widgets/habits_widgets.dart';
import 'daily_events_screen.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';
import 'mood_tracker_screen.dart';

class HabitsHomeScreen extends StatelessWidget {
  static const routeName = '/habits/home';

  const HabitsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habits Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(HabitFormScreen.routeName),
                  icon: const Icon(Icons.add),
                  label: const Text('New Habit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(DailyEventsScreen.routeName),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Daily Events'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completion Today'),
                  StreakBadge(streak: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Active Habits', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          HabitCard(
            title: 'Morning Quran (20 min)',
            onCheckIn: () => Navigator.of(context).pushNamed(HabitDetailScreen.routeName),
          ),
          HabitCard(
            title: 'Workout Session',
            onCheckIn: () => Navigator.of(context).pushNamed(HabitDetailScreen.routeName),
          ),
          const SizedBox(height: 12),
          Text('Consistency Calendar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          CompletionCalendar(
            entries: {
              DateTime.now().subtract(const Duration(days: 3)): true,
              DateTime.now().subtract(const Duration(days: 2)): true,
              DateTime.now().subtract(const Duration(days: 1)): false,
              DateTime.now(): true,
            },
          ),
          const SizedBox(height: 12),
          Text('Mood Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const MoodTrendChart(values: [6.2, 6.8, 7.0, 7.4, 7.1]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(MoodTrackerScreen.routeName),
              icon: const Icon(Icons.mood_outlined),
              label: const Text('Open Mood Tracker'),
            ),
          ),
        ],
      ),
    );
  }
}
