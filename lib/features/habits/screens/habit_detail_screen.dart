import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_style_picker.dart';
import '../widgets/habits_widgets.dart';
import '../widgets/log_habit_sheet.dart';
import 'habit_form_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  static const routeName = '/habits/detail';

  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Habit Detail')),
      body: habitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(habitByIdProvider(habitId)),
        ),
        data: (habit) {
          if (habit == null) {
            return const Center(child: Text('Habit not found'));
          }
          return _HabitDetailBody(habit: habit);
        },
      ),
    );
  }
}

class _HabitDetailBody extends ConsumerWidget {
  final Habit habit;

  const _HabitDetailBody({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(habitStatisticsProvider(habit.id));
    final logsAsync = ref.watch(logsForHabitProvider(habit.id));
    final color = habitColorFromHex(habit.color);
    final icon = kHabitIconOptions[habit.icon] ?? kHabitIconOptions[kDefaultHabitIcon]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: Theme.of(context).textTheme.titleLarge),
                  Wrap(
                    spacing: 6,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(habit.isGoodHabit ? 'Good habit' : 'Bad habit'),
                      ),
                      Chip(visualDensity: VisualDensity.compact, label: Text(habit.category)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  HabitFormScreen.routeName,
                  arguments: HabitFormArgs(existing: habit),
                );
                if (!context.mounted) {
                  return;
                }
                ref.invalidate(habitByIdProvider(habit.id));
                ref.invalidate(activeHabitsProvider);
              },
            ),
          ],
        ),
        if (habit.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(habit.description),
        ],
        const SizedBox(height: 16),
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(habitStatisticsProvider(habit.id)),
          ),
          data: (stats) => _StatsRow(stats: stats),
        ),
        const SizedBox(height: 16),
        Text('Consistency Calendar', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          ),
          data: (logs) {
            final now = DateTime.now();
            final entries = <DateTime, bool>{
              for (final log in logs.where((log) => log.completedAt.year == now.year && log.completedAt.month == now.month))
                DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day): true,
            };
            return CompletionCalendar(entries: entries);
          },
        ),
        const SizedBox(height: 16),
        Text(habit.isGoodHabit ? 'Mood Trend' : 'Intensity Trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          ),
          data: (logs) {
            final sorted = [...logs]..sort((a, b) => a.completedAt.compareTo(b.completedAt));
            if (habit.isGoodHabit) {
              final moodValues = sorted
                  .map((log) => habitMoodScore(log.mood))
                  .whereType<double>()
                  .toList(growable: false);
              return MoodTrendChart(values: moodValues);
            }
            final intensityValues = sorted
                .map((log) => log.intensity?.toDouble())
                .whereType<double>()
                .toList(growable: false);
            return intensityValues.isEmpty
                ? const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('No incidents logged yet')))
                : ComparisonBarChart(values: intensityValues);
          },
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => showLogHabitSheet(context, ref, habit),
          icon: const Icon(Icons.add_task_outlined),
          label: Text(habit.isGoodHabit ? 'Log occurrence' : 'Log incident'),
        ),
        const SizedBox(height: 20),
        Text('Log Timeline', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          ),
          data: (logs) => logs.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No logs yet'))
              : Column(children: logs.map((log) => _LogTile(habit: habit, log: log)).toList(growable: false)),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    final completionRate = (stats['completionRateThisMonth'] as double?)?.toStringAsFixed(0) ?? '0';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatChip(label: 'Current Streak', value: '${stats['currentStreak']}'),
        _StatChip(label: 'Best Streak', value: '${stats['bestStreak']}'),
        _StatChip(label: 'This Month', value: '$completionRate%'),
        _StatChip(label: 'Total Logs', value: '${stats['totalLogs']}'),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Habit habit;
  final HabitLog log;

  const _LogTile({required this.habit, required this.log});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = habit.isGoodHabit
        ? [
            if (log.mood != null) 'Mood: ${log.mood}',
            if (log.notes != null) log.notes!,
          ]
        : [
            if (log.situation != null) 'Situation: ${log.situation}',
            if (log.cause != null) 'Cause: ${log.cause}',
            if (log.trigger != null) 'Trigger: ${log.trigger}',
            if (log.intensity != null) 'Intensity: ${log.intensity}',
          ];
    return Card(
      child: ListTile(
        title: Text('${log.completedAt.toLocal()}'.split('.').first),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' | ')),
      ),
    );
  }
}
