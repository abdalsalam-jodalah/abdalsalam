import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/icon_badge.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_style_picker.dart';
import '../widgets/habits_widgets.dart';
import '../widgets/log_habit_sheet.dart';
import 'habit_form_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  static const routeName = '/habits/detail';
  static const String _title = 'Habit Detail';
  static const String _notFoundMessage = 'Habit not found';

  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));

    return Scaffold(
      appBar: AppBar(title: const Text(_title)),
      body: habitAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, _) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(habitByIdProvider(habitId)),
        ),
        data: (habit) {
          if (habit == null) {
            return const Center(child: Text(_notFoundMessage));
          }
          return _HabitDetailBody(habit: habit);
        },
      ),
    );
  }
}

class _HabitDetailBody extends ConsumerWidget {
  static const double _headerIconSize = 56;
  static const String _consistencyCalendarTitle = 'Consistency Calendar';
  static const String _moodTrendTitle = 'Mood Trend';
  static const String _intensityTrendTitle = 'Intensity Trend';
  static const String _logTimelineTitle = 'Log Timeline';
  static const String _noIncidentsTitle = 'No incidents logged yet';
  static const String _noIncidentsSubtitle = 'Log an incident to see the trend.';
  static const String _noLogsTitle = 'No logs yet';
  static const String _noLogsSubtitle = 'Log an entry to see it here.';
  static const String _logOccurrenceLabel = 'Log occurrence';
  static const String _logIncidentLabel = 'Log incident';

  final Habit habit;

  const _HabitDetailBody({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final statsAsync = ref.watch(habitStatisticsProvider(habit.id));
    final logsAsync = ref.watch(logsForHabitProvider(habit.id));
    final color = habitColorFromHex(habit.color);
    final icon = kHabitIconOptions[habit.icon] ?? kHabitIconOptions[kDefaultHabitIcon]!;

    return ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, color: color, size: _headerIconSize),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: theme.textTheme.titleLarge),
                  Wrap(
                    spacing: tokens.spacing.xs,
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
          SizedBox(height: tokens.spacing.sm),
          Text(habit.description),
        ],
        SizedBox(height: tokens.spacing.lg),
        AsyncSection<Map<String, dynamic>>(
          value: statsAsync,
          onRetry: () => ref.invalidate(habitStatisticsProvider(habit.id)),
          builder: (stats) => _buildStatsGrid(context, stats),
        ),
        AsyncSection<List<HabitLog>>(
          value: logsAsync,
          title: _consistencyCalendarTitle,
          onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          builder: (logs) {
            final now = DateTime.now();
            final entries = <DateTime, bool>{
              for (final log in logs.where((log) => log.completedAt.year == now.year && log.completedAt.month == now.month))
                DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day): true,
            };
            return CompletionCalendar(entries: entries);
          },
        ),
        AsyncSection<List<HabitLog>>(
          value: logsAsync,
          title: habit.isGoodHabit ? _moodTrendTitle : _intensityTrendTitle,
          onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          builder: (logs) {
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
                ? const EmptyState(title: _noIncidentsTitle, subtitle: _noIncidentsSubtitle, isCompact: true)
                : AppBarChart(values: intensityValues);
          },
        ),
        SizedBox(height: tokens.spacing.sm),
        FilledButton.icon(
          onPressed: () => showLogHabitSheet(context, ref, habit),
          icon: const Icon(Icons.add_task_outlined),
          label: Text(habit.isGoodHabit ? _logOccurrenceLabel : _logIncidentLabel),
        ),
        AsyncSection<List<HabitLog>>(
          value: logsAsync,
          title: _logTimelineTitle,
          onRetry: () => ref.invalidate(logsForHabitProvider(habit.id)),
          builder: (logs) => logs.isEmpty
              ? const EmptyState(title: _noLogsTitle, subtitle: _noLogsSubtitle, isCompact: true)
              : Column(
                  children: [
                    for (final log in logs)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                        child: _buildLogTile(context, log),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }
    final accent = AppModuleAccents.forModule('habits');
    final completionRate = (stats['completionRateThisMonth'] as double?)?.toStringAsFixed(0) ?? '0';
    return StatGrid(
      children: [
        StatTile(
          icon: Icons.local_fire_department_rounded,
          label: 'Current Streak',
          value: '${stats['currentStreak']}',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.emoji_events_outlined,
          label: 'Best Streak',
          value: '${stats['bestStreak']}',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.calendar_month_outlined,
          label: 'This Month',
          value: '$completionRate%',
          accentColor: accent,
        ),
        StatTile(
          icon: Icons.checklist_rtl_outlined,
          label: 'Total Logs',
          value: '${stats['totalLogs']}',
          accentColor: accent,
        ),
      ],
    );
  }

  Widget _buildLogTile(BuildContext context, HabitLog log) {
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
    return EntityTile(
      title: AppDateFormatter.dateTime(log.completedAt),
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' | '),
      icon: habit.isGoodHabit ? Icons.check_circle_outline : Icons.warning_amber_outlined,
      accentColor: habitColorFromHex(habit.color),
    );
  }
}
