import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/sports_providers.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/calendar';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const CalendarViewScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final logsAsync = ref.watch(logsInRangeProvider((start: monthStart, end: monthEnd)));

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded)
            Text(
              'Calendar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
              Text(
                '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftMonth(1)),
            ],
          ),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AsyncErrorView(
              error: error,
              onRetry: () => ref.invalidate(logsInRangeProvider((start: monthStart, end: monthEnd))),
            ),
            data: (logs) {
              final daysWithLogs = logs.map((log) => dateOnly(log.date)).toSet();
              return _MonthGrid(
                month: _visibleMonth,
                daysWithData: daysWithLogs,
                onDaySelected: (day) => _showDayDetail(context, day),
              );
            },
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Sport Calendar')), body: body);
  }

  void _showDayDetail(BuildContext context, DateTime day) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (sheetContext, scrollController) => _DayDetailSheet(day: day, scrollController: scrollController),
      ),
    ));
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> daysWithData;
  final ValueChanged<DateTime> onDaySelected;

  const _MonthGrid({required this.month, required this.daysWithData, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final end = DateTime(month.year, month.month + 1, 0);
    final days = List<DateTime>.generate(end.day, (index) => DateTime(month.year, month.month, index + 1));
    final today = dateOnly(DateTime.now());

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final hasData = daysWithData.contains(day);
        final isToday = day == today;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onDaySelected(day),
          child: Container(
            decoration: BoxDecoration(
              color: hasData ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              border: Border.all(
                color: isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                width: isToday ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('${day.day}'),
          ),
        );
      },
    );
  }
}

class _DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  final ScrollController scrollController;

  const _DayDetailSheet({required this.day, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsForDateProvider(day));
    final scheduleAsync = ref.watch(scheduleForDayProvider(day.weekday));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(allActiveExercisesProvider),
        ),
        data: (allExercises) {
          final exerciseById = {for (final exercise in allExercises) exercise.id: exercise};
          return ListView(
            controller: scrollController,
            children: [
              Text(
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('Scheduled', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              scheduleAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => AsyncErrorView(
                  error: error,
                  isCompact: true,
                  onRetry: () => ref.invalidate(scheduleForDayProvider(day.weekday)),
                ),
                data: (entries) => _buildScheduleList(entries, exerciseById),
              ),
              const Divider(height: 32),
              Text('Logged', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              logsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => AsyncErrorView(
                  error: error,
                  isCompact: true,
                  onRetry: () => ref.invalidate(logsForDateProvider(day)),
                ),
                data: (logs) => _buildLoggedList(logs, exerciseById),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleList(List<WeeklyScheduleEntry> entries, Map<String, Exercise> exerciseById) {
    if (entries.isEmpty) {
      return const Text('Nothing scheduled for this day of week.');
    }
    return Column(
      children: [
        for (final entry in entries)
          ListTile(
            dense: true,
            leading: const Icon(Icons.event_repeat_outlined),
            title: Text(exerciseById[entry.exerciseId]?.name ?? 'Unknown exercise'),
          ),
      ],
    );
  }

  Widget _buildLoggedList(List<ExerciseLog> logs, Map<String, Exercise> exerciseById) {
    if (logs.isEmpty) {
      return const Text('Nothing logged for this exact date.');
    }
    return Column(
      children: [
        for (final log in logs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(exerciseById[log.exerciseId]?.name ?? 'Unknown exercise'),
          ),
      ],
    );
  }
}
