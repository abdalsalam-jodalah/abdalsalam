import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/planning/goal.dart';
import '../providers/planning_providers.dart';

const _uuid = Uuid();

String goalScopeLabel(GoalScope scope) {
  switch (scope) {
    case GoalScope.life:
      return 'Life';
    case GoalScope.yearly:
      return 'Yearly';
    case GoalScope.quarterly:
      return 'Quarterly';
    case GoalScope.monthly:
      return 'Monthly';
    case GoalScope.weekly:
      return 'Weekly';
    case GoalScope.daily:
      return 'Daily';
  }
}

String goalAreaLabel(LifeArea area) {
  switch (area) {
    case LifeArea.mind:
      return 'Mind';
    case LifeArea.body:
      return 'Body';
    case LifeArea.money:
      return 'Money';
    case LifeArea.soul:
      return 'Soul';
  }
}

String goalStatusLabel(GoalStatus status) {
  switch (status) {
    case GoalStatus.notStarted:
      return 'Not started';
    case GoalStatus.inProgress:
      return 'In progress';
    case GoalStatus.achieved:
      return 'Achieved';
    case GoalStatus.abandoned:
      return 'Abandoned';
  }
}

/// Shows the add/edit form for a [Goal] and persists the result.
///
/// When [topicId] is provided (creating/editing a goal from the Life Planning
/// topics tree), it is attached to the created/updated goal automatically and
/// is not exposed as an editable field in the form.
///
/// Returns `true` if the goal was created/updated, `false`/`null` otherwise.
Future<bool> showGoalEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  Goal? existing,
  String? topicId,
  GoalScope? initialScope,
  LifeArea? initialArea,
}) async {
  final allGoals = ref.read(activeGoalsProvider).maybeWhen(data: (list) => list, orElse: () => const <Goal>[]);
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  GoalScope selectedScope = existing?.scope ?? initialScope ?? GoalScope.daily;
  GoalStatus selectedStatus = existing?.status ?? GoalStatus.notStarted;
  DateTime? selectedDate = existing?.targetDate ?? DateTime.now();
  String? selectedParentId = existing?.parentGoalId;
  LifeArea? selectedArea = existing?.area ?? initialArea;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'New Goal' : 'Edit Goal'),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalScope>(
                  initialValue: selectedScope,
                  items: GoalScope.values
                      .map((scope) => DropdownMenuItem(value: scope, child: Text(goalScopeLabel(scope))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedScope = value ?? selectedScope),
                  decoration: const InputDecoration(labelText: 'Scope', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GoalStatus>(
                  initialValue: selectedStatus,
                  items: GoalStatus.values
                      .map((status) => DropdownMenuItem(value: status, child: Text(goalStatusLabel(status))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedStatus = value ?? selectedStatus),
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedParentId,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    for (final candidate in allGoals.where((g) => g.id != existing?.id))
                      DropdownMenuItem<String?>(value: candidate.id, child: Text(candidate.title)),
                  ],
                  onChanged: (value) => setDialogState(() => selectedParentId = value),
                  decoration: const InputDecoration(labelText: 'Linked goal (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LifeArea>(
                  initialValue: selectedArea,
                  items: LifeArea.values
                      .map((area) => DropdownMenuItem(value: area, child: Text(goalAreaLabel(area))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => selectedArea = value),
                  validator: (value) => value == null ? 'Pick a life area' : null,
                  decoration: const InputDecoration(labelText: 'Life area', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target date'),
                  subtitle: Text(selectedDate == null
                      ? 'Not set'
                      : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
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

  final repo = ref.read(goalRepositoryProvider);
  final now = DateTime.now();

  final result = existing == null
      ? await repo.create(
          Goal(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            title: title,
            description: description.isEmpty ? null : description,
            scope: selectedScope,
            status: selectedStatus,
            targetDate: selectedDate,
            parentGoalId: selectedParentId,
            area: selectedArea,
            topicId: topicId ?? existing?.topicId,
          ),
        )
      : await repo.update(
          existing.copyWith(
            title: title,
            description: description.isEmpty ? null : description,
            scope: selectedScope,
            status: selectedStatus,
            targetDate: selectedDate,
            parentGoalId: selectedParentId,
            area: selectedArea,
            updatedAt: now,
          ),
        );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? (existing == null ? 'Goal created' : 'Goal updated') : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  ref.invalidate(activeGoalsProvider);
  ref.invalidate(todaysGoalsProvider);
  final resolvedTopicId = topicId ?? existing?.topicId;
  if (resolvedTopicId != null) {
    ref.invalidate(goalsForTopicProvider(resolvedTopicId));
  }

  return result.isSuccess;
}
