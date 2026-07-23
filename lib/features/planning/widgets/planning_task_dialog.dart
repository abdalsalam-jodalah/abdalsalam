import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/planning_task.dart';
import '../providers/planning_providers.dart';

const _uuid = Uuid();

/// Shows the add/edit form for a [PlanningTask] and persists the result.
///
/// - Pass [date] to create/edit a Day Planning task for that day.
/// - Pass [fixedGoalId] to create/edit a Life Planning task that belongs to
///   that goal (the goal picker is hidden since the parent is implicit).
/// - Pass [linkableGoals] to show a "link to a goal" picker populated with
///   that list (Day Planning passes that day's own goals, so a task can be
///   linked to one of the goals set for the same day).
/// - [order] is only used when creating a new task (its position at the end
///   of the current list).
Future<bool> showPlanningTaskDialog(
  BuildContext context,
  WidgetRef ref, {
  PlanningTask? existing,
  DateTime? date,
  String? fixedGoalId,
  List<Goal> linkableGoals = const <Goal>[],
  int order = 0,
}) async {
  final allowGoalLink = linkableGoals.isNotEmpty;
  final allGoals = linkableGoals;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  String? selectedGoalId =
      allGoals.any((goal) => goal.id == existing?.goalId) ? existing?.goalId : null;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'New Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Form(
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
                if (allowGoalLink) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedGoalId,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Not linked to a goal')),
                      for (final goal in allGoals)
                        DropdownMenuItem<String?>(value: goal.id, child: Text(goal.title)),
                    ],
                    onChanged: (value) => setDialogState(() => selectedGoalId = value),
                    decoration:
                        const InputDecoration(labelText: 'Link to goal (optional)', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    ),
  );

  if (saved != true) {
    titleController.dispose();
    descriptionController.dispose();
    return false;
  }

  final title = titleController.text.trim();
  final description = descriptionController.text.trim();
  titleController.dispose();
  descriptionController.dispose();

  final repo = ref.read(planningTaskRepositoryProvider);
  final now = DateTime.now();
  final resolvedGoalId = fixedGoalId ?? selectedGoalId;

  final result = existing == null
      ? await repo.create(
          PlanningTask(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            title: title,
            description: description.isEmpty ? null : description,
            date: date,
            goalId: resolvedGoalId,
            order: order,
          ),
        )
      : await repo.update(
          existing.copyWith(
            title: title,
            description: description.isEmpty ? null : description,
            goalId: resolvedGoalId,
            clearGoalId: resolvedGoalId == null,
            updatedAt: now,
          ),
        );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? (existing == null ? 'Task created' : 'Task updated') : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  if (date != null) {
    ref.invalidate(tasksForDateProvider(date));
  }
  final goalIdForInvalidate = fixedGoalId ?? existing?.goalId ?? selectedGoalId;
  if (goalIdForInvalidate != null) {
    ref.invalidate(tasksForGoalProvider(goalIdForInvalidate));
  }

  return result.isSuccess;
}
