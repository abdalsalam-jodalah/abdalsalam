import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/user_error_messages.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/planning_task.dart';
import '../providers/planning_providers.dart';
import '../widgets/planning_task_dialog.dart';
import '../widgets/reorderable_task_list.dart';

const _uuid = Uuid();

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class DayPlanningScreen extends ConsumerStatefulWidget {
  static const routeName = '/planning/day';

  const DayPlanningScreen({super.key});

  @override
  ConsumerState<DayPlanningScreen> createState() => _DayPlanningScreenState();
}

class _DayPlanningScreenState extends ConsumerState<DayPlanningScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _shiftDay(int delta) {
    setState(() => _selectedDate = _dateOnly(_selectedDate.add(Duration(days: delta))));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsForDateProvider(_selectedDate));
    final tasksAsync = ref.watch(tasksForDateProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(_selectedDate)),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftDay(-1)),
          IconButton(icon: const Icon(Icons.calendar_today_outlined), onPressed: _pickDate),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftDay(1)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGoalsSection(goalsAsync),
          const Divider(height: 32),
          _buildTasksSection(tasksAsync),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(AsyncValue<List<Goal>> goalsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Goals for today', style: Theme.of(context).textTheme.titleMedium),
            IconButton(icon: const Icon(Icons.add), onPressed: _addGoal),
          ],
        ),
        goalsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const Text('Failed to load goals'),
          data: (goals) {
            if (goals.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No goals set for this day yet.'),
              );
            }
            return Column(
              children: [
                for (final goal in goals)
                  CheckboxListTile(
                    value: goal.status == GoalStatus.achieved,
                    onChanged: (value) => _toggleGoal(goal, value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: goal.status == GoalStatus.achieved
                          ? const TextStyle(decoration: TextDecoration.lineThrough)
                          : null,
                    ),
                    subtitle: goal.description != null && goal.description!.isNotEmpty
                        ? Text(goal.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteGoal(goal),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTasksSection(AsyncValue<List<PlanningTask>> tasksAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tasks', style: Theme.of(context).textTheme.titleMedium),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _addOrEditTask()),
          ],
        ),
        tasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const Text('Failed to load tasks'),
          data: (tasks) => ReorderableTaskList(
            tasks: tasks,
            onToggle: _toggleTask,
            onEdit: (task) => _addOrEditTask(existing: task),
            onDelete: _deleteTask,
            onReorder: _reorderTasks,
          ),
        ),
      ],
    );
  }

  Future<void> _addGoal() async {
    final result = await showDialog<_DayGoalDialogResult>(
      context: context,
      builder: (_) => const _DayGoalDialogContent(),
    );

    if (result == null) return;

    final service = ref.read(goalServiceProvider);
    final now = DateTime.now();
    final saveResult = await service.create(
      Goal(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: planningUserId,
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
        scope: GoalScope.daily,
        status: GoalStatus.notStarted,
        targetDate: _selectedDate,
      ),
    );
    if (!mounted) return;
    if (saveResult.isFailure) _showFailureSnackBar();
    ref.invalidate(goalsForDateProvider(_selectedDate));
    ref.invalidate(activeGoalsProvider);
  }

  Future<void> _toggleGoal(Goal goal, bool completed) async {
    final service = ref.read(goalServiceProvider);
    final updateResult = await service.update(
      goal.copyWith(
        status: completed ? GoalStatus.achieved : GoalStatus.notStarted,
        updatedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (updateResult.isFailure) _showFailureSnackBar();
    ref.invalidate(goalsForDateProvider(_selectedDate));
    ref.invalidate(activeGoalsProvider);
  }

  Future<void> _deleteGoal(Goal goal) async {
    final service = ref.read(goalServiceProvider);
    final deleteResult = await service.softDelete(goal.id);
    if (!mounted) return;
    if (deleteResult.isFailure) _showFailureSnackBar();
    ref.invalidate(goalsForDateProvider(_selectedDate));
    ref.invalidate(activeGoalsProvider);
  }

  Future<void> _addOrEditTask({PlanningTask? existing}) async {
    final currentTasks = ref.read(tasksForDateProvider(_selectedDate)).maybeWhen(
          data: (list) => list,
          orElse: () => const <PlanningTask>[],
        );
    final todaysGoals = ref.read(goalsForDateProvider(_selectedDate)).maybeWhen(
          data: (list) => list,
          orElse: () => const <Goal>[],
        );
    await showPlanningTaskDialog(
      context,
      ref,
      existing: existing,
      date: _selectedDate,
      linkableGoals: todaysGoals,
      order: currentTasks.length,
    );
  }

  Future<void> _toggleTask(PlanningTask task, bool completed) async {
    final service = ref.read(planningTaskServiceProvider);
    final updateResult = await service.update(task.copyWith(isCompleted: completed, updatedAt: DateTime.now()));
    if (!mounted) return;
    if (updateResult.isFailure) _showFailureSnackBar();
    ref.invalidate(tasksForDateProvider(_selectedDate));
  }

  Future<void> _deleteTask(PlanningTask task) async {
    final service = ref.read(planningTaskServiceProvider);
    final deleteResult = await service.softDelete(task.id);
    if (!mounted) return;
    if (deleteResult.isFailure) _showFailureSnackBar();
    ref.invalidate(tasksForDateProvider(_selectedDate));
  }

  Future<void> _reorderTasks(List<PlanningTask> reordered) async {
    final service = ref.read(planningTaskServiceProvider);
    final updated = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i, updatedAt: DateTime.now()),
    ];
    final updateResult = await service.updateBulk(updated);
    if (!mounted) return;
    if (updateResult.isFailure) _showFailureSnackBar();
    ref.invalidate(tasksForDateProvider(_selectedDate));
  }

  void _showFailureSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(UserErrorMessages.generic), backgroundColor: Colors.red),
    );
  }
}

class _DayGoalDialogResult {
  _DayGoalDialogResult(this.title, this.description);

  final String title;
  final String description;
}

class _DayGoalDialogContent extends StatefulWidget {
  const _DayGoalDialogContent();

  @override
  State<_DayGoalDialogContent> createState() => _DayGoalDialogContentState();
}

class _DayGoalDialogContentState extends State<_DayGoalDialogContent> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Goal'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
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
                _DayGoalDialogResult(titleController.text.trim(), descriptionController.text.trim()),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
