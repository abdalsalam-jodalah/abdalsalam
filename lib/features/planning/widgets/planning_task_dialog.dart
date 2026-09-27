import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/planning_providers.dart';

const _uuid = Uuid();
const String _taskCreatedMessage = 'Task created';
const String _taskUpdatedMessage = 'Task updated';

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
  final result = await showDialog<_PlanningTaskResult>(
    context: context,
    builder: (_) => _PlanningTaskDialogContent(existing: existing, linkableGoals: linkableGoals),
  );

  if (result == null) return false;

  final service = ref.read(planningTaskServiceProvider);
  final now = DateTime.now();
  final resolvedGoalId = fixedGoalId ?? result.selectedGoalId;

  final saveResult = existing == null
      ? await service.create(
          PlanningTask(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            date: date,
            goalId: resolvedGoalId,
            order: order,
          ),
        )
      : await service.update(
          existing.copyWith(
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            goalId: resolvedGoalId,
            clearGoalId: resolvedGoalId == null,
            updatedAt: now,
          ),
        );

  if (!context.mounted) return false;
  if (saveResult.isFailure) {
    AppFeedback.showError(context, saveResult.error!);
    return false;
  }

  AppFeedback.showSuccess(context, existing == null ? _taskCreatedMessage : _taskUpdatedMessage);
  if (date != null) {
    ref.invalidate(tasksForDateProvider(date));
  }
  final goalIdForInvalidate = fixedGoalId ?? existing?.goalId ?? result.selectedGoalId;
  if (goalIdForInvalidate != null) {
    ref.invalidate(tasksForGoalProvider(goalIdForInvalidate));
  }

  return true;
}

class _PlanningTaskResult {
  _PlanningTaskResult(this.title, this.description, this.selectedGoalId);

  final String title;
  final String description;
  final String? selectedGoalId;
}

class _PlanningTaskDialogContent extends StatefulWidget {
  const _PlanningTaskDialogContent({required this.existing, required this.linkableGoals});

  final PlanningTask? existing;
  final List<Goal> linkableGoals;

  @override
  State<_PlanningTaskDialogContent> createState() => _PlanningTaskDialogContentState();
}

class _PlanningTaskDialogContentState extends State<_PlanningTaskDialogContent> {
  static const String _titleRequiredMessage = 'Title is required';
  static const String _notLinkedLabel = 'Not linked to a goal';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  String? selectedGoalId;

  bool get allowGoalLink => widget.linkableGoals.isNotEmpty;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    selectedGoalId = widget.linkableGoals.any((goal) => goal.id == widget.existing?.goalId)
        ? widget.existing?.goalId
        : null;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        _PlanningTaskResult(titleController.text.trim(), descriptionController.text.trim(), selectedGoalId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: widget.existing == null ? 'New Task' : 'Edit Task',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      onSubmit: _submit,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => (value == null || value.trim().isEmpty) ? _titleRequiredMessage : null,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            if (allowGoalLink) ...[
              SizedBox(height: spacing.md),
              DropdownButtonFormField<String?>(
                initialValue: selectedGoalId,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text(_notLinkedLabel)),
                  for (final goal in widget.linkableGoals)
                    DropdownMenuItem<String?>(value: goal.id, child: Text(goal.title)),
                ],
                onChanged: (value) => setState(() => selectedGoalId = value),
                decoration: const InputDecoration(labelText: 'Link to goal (optional)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
