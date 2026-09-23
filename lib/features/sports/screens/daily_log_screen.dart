import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/user_error_messages.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../data/models/sports/exercise_set_log.dart';
import '../providers/sports_providers.dart';
import '../widgets/reorderable_sport_list.dart';
import '../widgets/sports_widgets.dart';

const _uuid = Uuid();

void _showFailureSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(UserErrorMessages.generic), backgroundColor: Colors.red),
  );
}

class DailyLogScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/daily-log';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const DailyLogScreen({super.key, this.embedded = false});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
    if (picked != null) {
      setState(() => _selectedDate = dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateNav = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftDay(-1)),
        TextButton(onPressed: _pickDate, child: Text(_formatDate(_selectedDate))),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftDay(1)),
      ],
    );

    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            Row(
              children: [
                Text(
                  'Daily Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            dateNav,
            const SizedBox(height: 12),
          ],
          Row(
            children: const [
              RestTimer(seconds: 60),
              SizedBox(width: 8),
              RestTimer(seconds: 90),
            ],
          ),
          const SizedBox(height: 16),
          _DailyLogBody(key: ValueKey('daily-log-${_selectedDate.toIso8601String()}'), date: _selectedDate),
        ],
      ),
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
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
  DateTime get date => widget.date;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(logsForDateProvider(date));
    final exercisesAsync = ref.watch(allActiveExercisesProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('Failed to load logs')),
      data: (logs) {
        return exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Failed to load exercises')),
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
                      spacing: 8,
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
                ReorderableSportList<ExerciseLog>(
                  items: logs,
                  keyOf: (log) => log.id,
                  emptyState: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nothing logged for this day yet.'),
                  ),
                  itemBuilder: (context, log, index) {
                    final exercise = exerciseById[log.exerciseId];
                    return _LogTile(
                      key: ValueKey('tile-${log.id}'),
                      log: log,
                      exercise: exercise,
                      onDelete: () => _deleteLog(log),
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
    if (updateResult.isFailure) _showFailureSnackBar(context);
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _deleteLog(ExerciseLog log) async {
    final service = ref.read(exerciseLogServiceProvider);
    final deleteResult = await service.softDelete(log.id);
    if (!mounted) {
      return;
    }
    if (deleteResult.isFailure) _showFailureSnackBar(context);
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _loadFromSchedule(List<ExerciseLog> currentLogs, List<Exercise> allExercises) async {
    final scheduleEntries = await ref.read(scheduleForDayProvider(date.weekday).future);
    final alreadyLoggedExerciseIds = currentLogs.map((log) => log.exerciseId).toSet();
    final toAdd = scheduleEntries.where((entry) => !alreadyLoggedExerciseIds.contains(entry.exerciseId));

    final service = ref.read(exerciseLogServiceProvider);
    final now = DateTime.now();
    var order = currentLogs.length;
    var hasFailure = false;
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
      if (createResult.isFailure) hasFailure = true;
      order++;
    }
    if (!mounted) {
      return;
    }
    if (hasFailure) _showFailureSnackBar(context);
    ref.invalidate(logsForDateProvider(date));
  }

  Future<void> _showAddExerciseSheet(List<Exercise> allExercises, List<ExerciseLog> currentLogs) async {
    final loggedIds = currentLogs.map((log) => log.exerciseId).toSet();
    final available = allExercises.where((exercise) => !loggedIds.contains(exercise.id)).toList();

    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (sheetContext) {
        if (available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('All catalog exercises are already logged for this day, or none exist yet.'),
          );
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
    if (createResult.isFailure) _showFailureSnackBar(context);
    ref.invalidate(logsForDateProvider(date));
  }
}

class _LogTile extends ConsumerWidget {
  final ExerciseLog log;
  final Exercise? exercise;
  final VoidCallback onDelete;

  const _LogTile({super.key, required this.log, required this.exercise, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCardio = exercise?.trackingType == ExerciseTrackingType.cardio;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_indicator),
        title: Text(exercise?.name ?? 'Unknown exercise'),
        subtitle: isCardio ? _cardioSummary() : null,
        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        children: [
          if (isCardio)
            _CardioForm(key: ValueKey('cardio-${log.id}'), log: log)
          else
            _StrengthSets(key: ValueKey('strength-${log.id}'), log: log, exerciseId: log.exerciseId),
        ],
      ),
    );
  }

  Widget? _cardioSummary() {
    final parts = <String>[];
    if (log.steps != null) parts.add('${log.steps} steps');
    if (log.durationSeconds != null) parts.add('${(log.durationSeconds! / 60).toStringAsFixed(0)} min');
    if (log.distanceKm != null) parts.add('${log.distanceKm!.toStringAsFixed(1)} km');
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }
}

class _CardioForm extends ConsumerStatefulWidget {
  final ExerciseLog log;

  const _CardioForm({super.key, required this.log});

  @override
  ConsumerState<_CardioForm> createState() => _CardioFormState();
}

class _CardioFormState extends ConsumerState<_CardioForm> {
  late final TextEditingController _stepsController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: widget.log.steps?.toString() ?? '');
    _durationController = TextEditingController(text: widget.log.durationSeconds?.toString() ?? '');
    _distanceController = TextEditingController(text: widget.log.distanceKm?.toString() ?? '');
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(exerciseLogServiceProvider);
    final updateResult = await service.update(
      widget.log.copyWith(
        steps: int.tryParse(_stepsController.text),
        durationSeconds: int.tryParse(_durationController.text),
        distanceKm: double.tryParse(_distanceController.text),
        updatedAt: DateTime.now(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (updateResult.isFailure) _showFailureSnackBar(context);
    ref.invalidate(logsForDateProvider(dateOnly(widget.log.date)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Steps'),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (sec)'),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distance (km)'),
              onSubmitted: (_) => _save(),
              onEditingComplete: _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// A [ConsumerStatefulWidget] rather than a stateless [ConsumerWidget] so
/// [ref] stays bound to a stable [State] across the `await showDialog(...)`
/// call below — see the comment on `_CategorySection` in
/// exercise_library_screen.dart.
class _StrengthSets extends ConsumerStatefulWidget {
  final ExerciseLog log;
  final String exerciseId;

  const _StrengthSets({super.key, required this.log, required this.exerciseId});

  @override
  ConsumerState<_StrengthSets> createState() => _StrengthSetsState();
}

class _StrengthSetsState extends ConsumerState<_StrengthSets> {
  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(setsForLogProvider(widget.log.id));
    final prAsync = ref.watch(personalRecordProvider(widget.exerciseId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          setsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const Text('Failed to load sets'),
            data: (sets) {
              if (sets.isEmpty) {
                return const Text('No sets logged yet.');
              }
              return Column(
                children: [
                  for (final set in sets)
                    Row(
                      key: ValueKey(set.id),
                      children: [
                        Expanded(child: Text('Set ${set.setNumber}')),
                        Expanded(child: Text('${set.reps} reps')),
                        Expanded(
                          child: Text(set.weightKg != null ? '${set.weightKg} kg' : '-'),
                        ),
                        prAsync.maybeWhen(
                          data: (pr) => (pr != null && set.weightKg != null && set.weightKg! >= pr)
                              ? const PRBadge(label: 'PR')
                              : const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddSetDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add set'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSetDialog() async {
    final result = await showDialog<_AddSetResult>(
      context: context,
      builder: (_) => const _AddSetDialogContent(),
    );

    if (result == null) return;

    if (!mounted) {
      return;
    }
    final currentSets = ref.read(setsForLogProvider(widget.log.id)).maybeWhen(
          data: (list) => list,
          orElse: () => const <ExerciseSetLog>[],
        );

    final service = ref.read(exerciseSetLogServiceProvider);
    final now = DateTime.now();
    final createResult = await service.create(
      ExerciseSetLog(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: sportUserId,
        exerciseLogId: widget.log.id,
        setNumber: currentSets.length + 1,
        reps: result.reps,
        weightKg: result.weight,
      ),
    );
    if (!mounted) {
      return;
    }
    if (createResult.isFailure) _showFailureSnackBar(context);
    ref.invalidate(setsForLogProvider(widget.log.id));
    ref.invalidate(personalRecordProvider(widget.exerciseId));
  }
}

class _AddSetResult {
  _AddSetResult(this.reps, this.weight);

  final int reps;
  final double? weight;
}

class _AddSetDialogContent extends StatefulWidget {
  const _AddSetDialogContent();

  @override
  State<_AddSetDialogContent> createState() => _AddSetDialogContentState();
}

class _AddSetDialogContentState extends State<_AddSetDialogContent> {
  final formKey = GlobalKey<FormState>();
  final repsController = TextEditingController();
  final weightController = TextEditingController();

  @override
  void dispose() {
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Set'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps', border: OutlineInputBorder()),
              validator: (value) => (value == null || int.tryParse(value) == null) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg, optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _AddSetResult(int.parse(repsController.text), double.tryParse(weightController.text)),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
