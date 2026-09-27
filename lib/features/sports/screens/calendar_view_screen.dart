import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/month_heatmap.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/sports_providers.dart';

class CalendarViewScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/calendar';
  static const String title = 'Calendar';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const CalendarViewScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static const double _sheetInitialSize = 0.6;
  static const double _sheetMinSize = 0.4;
  static const double _sheetMaxSize = 0.9;

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final monthEnd = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final logsAsync = ref.watch(logsInRangeProvider((start: monthStart, end: monthEnd)));

    final body = ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        if (widget.embedded) AppSectionHeader(title: CalendarViewScreen.title, padding: EdgeInsets.zero),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
            Text(_monthFormat.format(_visibleMonth), style: Theme.of(context).textTheme.titleMedium),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftMonth(1)),
          ],
        ),
        SizedBox(height: tokens.spacing.sm),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(logsInRangeProvider((start: monthStart, end: monthEnd))),
          ),
          data: (logs) {
            final daysWithLogs = logs.map((log) => dateOnly(log.date)).toSet();
            return MonthHeatmap(
              month: _visibleMonth,
              intensityForDay: (day) => daysWithLogs.contains(day) ? 1 : 0,
              onDayTap: (day) => _showDayDetail(context, day),
            );
          },
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Sport Calendar')), body: body);
  }

  void _showDayDetail(BuildContext context, DateTime day) {
    unawaited(showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: _sheetInitialSize,
        minChildSize: _sheetMinSize,
        maxChildSize: _sheetMaxSize,
        expand: false,
        builder: (sheetContext, scrollController) => _DayDetailSheet(day: day, scrollController: scrollController),
      ),
    ));
  }
}

class _DayDetailSheet extends ConsumerWidget {
  final DateTime day;
  final ScrollController scrollController;

  const _DayDetailSheet({required this.day, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final logsAsync = ref.watch(logsForDateProvider(day));
    final scheduleAsync = ref.watch(scheduleForDayProvider(day.weekday));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return exercisesAsync.when(
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
            Text(AppDateFormatter.date(day), style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: tokens.spacing.lg),
            AppSectionHeader(title: 'Scheduled', padding: EdgeInsets.zero),
            scheduleAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => AsyncErrorView(
                error: error,
                isCompact: true,
                onRetry: () => ref.invalidate(scheduleForDayProvider(day.weekday)),
              ),
              data: (entries) => _buildScheduleList(entries, exerciseById),
            ),
            Divider(height: tokens.spacing.xxl),
            AppSectionHeader(title: 'Logged', padding: EdgeInsets.zero),
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
