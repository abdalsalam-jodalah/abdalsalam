import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/sports_providers.dart';
import '../widgets/reorderable_sport_list.dart';
import '../widgets/sports_log_tile.dart';
import '../widgets/sports_widgets.dart';

const _uuid = Uuid();

class DailyLogScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/daily-log';
  static const String title = 'Daily Log';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const DailyLogScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  static const int _restTimerShort = 60;
  static const int _restTimerLong = 90;

  DateTime _selectedDate = dateOnly(DateTime.now());

  void _shiftDay(int delta) {
    setState(() => _selectedDate = dateOnly(_selectedDate.add(Duration(days: delta))));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted) {
      return;
    }
    if (picked != null) {
      setState(() => _selectedDate = dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final dateNav = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftDay(-1)),
        TextButton(onPressed: _pickDate, child: Text(AppDateFormatter.date(_selectedDate))),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftDay(1)),
      ],
    );

    final body = ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        if (widget.embedded) ...[
          const AppSectionHeader(title: DailyLogScreen.title, padding: EdgeInsets.zero),
          dateNav,
          SizedBox(height: tokens.spacing.sm),
        ],
        Row(
          children: [
            const RestTimer(seconds: _restTimerShort),
            SizedBox(width: tokens.spacing.sm),
            const RestTimer(seconds: _restTimerLong),
          ],
        ),
        SizedBox(height: tokens.spacing.lg),
        _DailyLogBody(key: ValueKey('daily-log-${_selectedDate.toIso8601String()}'), date: _selectedDate),
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(DailyLogScreen.title),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftDay(-1)),
          IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftDay(1)),
        ],
      ),
      body: body,
    );
  }
}

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await` calls below —
/// see the comment on `_CategorySection` in exercise_library_screen.dart.
class _DailyLogBody extends ConsumerStatefulWidget {
  final DateTime date;

  const _DailyLogBody({super.key, required this.date});

  @override
  ConsumerState<_DailyLogBody> createState() => _DailyLogBodyState();
}

class _DailyLogBodyState extends ConsumerState<_DailyLogBody> {
  static const String _emptyTitle = 'Nothing logged for this day yet.';
  static const String _emptySubtitle = 'Load your schedule or add an exercise to get started.';

  DateTime get date => widget.date;

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final logsAsync = ref.watch(logsForDateProvider(date));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(logsForDateProvider(date)),
      ),
      data: (logs) {
        return exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AsyncErrorView(
            error: error,
            isCompact: true,
            onRetry: () => ref.invalidate(allActiveExercisesProvider),
          ),
          data: (allExercises) {
            final exerciseById = {for (final exercise in allExercises) exercise.id: exercise};

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exercises performed', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: spacing.sm,
                      children: [
                        TextButton.icon(
                          onPressed: () => _loadFromSchedule(logs, allExercises),
                          icon: const Icon(Icons.event_repeat),
                          label: const Text('Load schedule'),
                        ),
                        TextButton.icon(
                          onPressed: () => _showAddExerciseSheet(allExercises, logs),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: spacing.sm),
                ReorderableSportList<ExerciseLog>(
                  items: logs,
                  keyOf: (log) => log.id,
                  emptyState: const EmptyState(
                    title: _emptyTitle,
                    subtitle: _emptySubtitle,
                    icon: Icons.fitness_center_rounded,
                    isCompact: true,
                  ),
                  itemBuilder: (context, log, index) {
                    final exercise = exerciseById[log.exerciseId];
                    return Padding(
                      padding: EdgeInsets.only(bottom: spacing.sm),
                      child: SportsLogTile(
                        key: ValueKey('tile-${log.id}'),
                        log: log,
                        exercise: exercise,
                        onDelete: () => _deleteLog(log),
                      ),
                    );
                  },
                  onReorder: (reordered) => _reorderLogs(reordered),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reorderLogs(List<ExerciseLog> reordered) async {
    final service = ref.read(exerciseLogServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!mounted) {
      return;
    }
    if (updateResult.isFailure) {
      AppFeedback.showError(context, updateResult.error!);
    }
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _deleteLog(ExerciseLog log) async {
    final service = ref.read(exerciseLogServiceProvider);
    final deleteResult = await service.softDelete(log.id);
    if (!mounted) {
      return;
    }
    if (deleteResult.isFailure) {
      AppFeedback.showError(context, deleteResult.error!);
    }
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _loadFromSchedule(List<ExerciseLog> currentLogs, List<Exercise> allExercises) async {
    final scheduleEntries = await ref.read(scheduleForDayProvider(date.weekday).future);
    final alreadyLoggedExerciseIds = currentLogs.map((log) => log.exerciseId).toSet();
    final toAdd = scheduleEntries.where((entry) => !alreadyLoggedExerciseIds.contains(entry.exerciseId));

    final service = ref.read(exerciseLogServiceProvider);
    final now = DateTime.now();
    var order = currentLogs.length;
    AppError? failure;
    for (final entry in toAdd) {
      final createResult = await service.create(
        ExerciseLog(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: sportUserId,
          date: date,
          exerciseId: entry.exerciseId,
          order: order,
          scheduleEntryId: entry.id,
        ),
      );
      if (createResult.isFailure) {
        failure ??= createResult.error;
      }
      order++;
    }
    if (!mounted) {
      return;
    }
    if (failure != null) {
      AppFeedback.showError(context, failure);
    }
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _showAddExerciseSheet(List<Exercise> allExercises, List<ExerciseLog> currentLogs) async {
    final loggedIds = currentLogs.map((log) => log.exerciseId).toSet();
    final available = allExercises.where((exercise) => !loggedIds.contains(exercise.id)).toList();

    final selected = await showAppBottomSheet<Exercise>(
      context,
      title: 'Add exercise',
      builder: (sheetContext) {
        if (available.isEmpty) {
          return const Text('All catalog exercises are already logged for this day, or none exist yet.');
        }
        return ListView(
          shrinkWrap: true,
          children: [
            for (final exercise in available)
              ListTile(
                title: Text(exercise.name),
                onTap: () => Navigator.pop(sheetContext, exercise),
              ),
          ],
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final service = ref.read(exerciseLogServiceProvider);
    final now = DateTime.now();
    final createResult = await service.create(
      ExerciseLog(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        date: date,
        exerciseId: selected.id,
        order: currentLogs.length,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) {
      AppFeedback.showError(context, createResult.error!);
    }
    ref.invalidate(logsForDateProvider(date));
  }
}
