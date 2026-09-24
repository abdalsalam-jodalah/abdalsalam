import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/habits_providers.dart';
import '../widgets/habits_widgets.dart';
import '../widgets/log_habit_sheet.dart';
import 'habit_detail_screen.dart';
import 'habit_form_screen.dart';

class HabitsHomeScreen extends ConsumerWidget {
  static const routeName = '/habits/home';

  const HabitsHomeScreen({super.key});

  Future<void> _openNewHabit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(HabitFormScreen.routeName);
    if (!context.mounted) {
      return;
    }
    ref.invalidate(activeHabitsProvider);
  }

  Future<void> _openDetail(BuildContext context, Habit habit) async {
    await Navigator.of(context).pushNamed(HabitDetailScreen.routeName, arguments: habit.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(activeHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits Home')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(activeHabitsProvider),
        ),
        data: (habits) {
          final goodHabits = habits.where((habit) => habit.isGoodHabit).toList(growable: false);
          final badHabits = habits.where((habit) => !habit.isGoodHabit).toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: () => _openNewHabit(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New Habit'),
              ),
              const SizedBox(height: 12),
              _TodayCompletionCard(goodHabits: goodHabits),
              const SizedBox(height: 16),
              Text('Building', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (goodHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No good habits yet. Add one above.'),
                )
              else
                ...goodHabits.map((habit) => _HabitCardEntry(habit: habit, onTap: () => _openDetail(context, habit))),
              const SizedBox(height: 16),
              Text('Breaking', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (badHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No bad habits tracked.'),
                )
              else
                ...badHabits.map((habit) => _HabitCardEntry(habit: habit, onTap: () => _openDetail(context, habit))),
            ],
          );
        },
      ),
    );
  }
}

class _TodayCompletionCard extends ConsumerWidget {
  final List<Habit> goodHabits;

  const _TodayCompletionCard({required this.goodHabits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goodHabits.isEmpty) {
      return const SizedBox.shrink();
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Completion Today'),
            Consumer(
              builder: (context, ref, _) {
                final logsAsync = <AsyncValue<List<HabitLog>>>[
                  for (final habit in goodHabits) ref.watch(logsForHabitProvider(habit.id)),
                ];
                final loaded = logsAsync.every((value) => value.hasValue);
                if (!loaded) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final completedToday = logsAsync.where((value) {
                  final logs = value.value ?? const <HabitLog>[];
                  return logs.any((log) {
                    final completedAt = log.completedAt;
                    return DateTime(completedAt.year, completedAt.month, completedAt.day) == todayOnly;
                  });
                }).length;
                final percent = goodHabits.isEmpty ? 0 : (completedToday / goodHabits.length * 100).round();
                return Text('$completedToday / ${goodHabits.length} ($percent%)');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCardEntry extends ConsumerWidget {
  final Habit habit;
  final VoidCallback onTap;

  const _HabitCardEntry({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(habitStatisticsProvider(habit.id));
    final streak = statsAsync.value?['currentStreak'] as int? ?? 0;
    return HabitCard(
      habit: habit,
      currentStreak: streak,
      onTap: onTap,
      onCheckIn: () => showLogHabitSheet(context, ref, habit),
    );
  }
}
