import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/goal.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/planning_providers.dart';

const _uuid = Uuid();
const String _goalCreatedMessage = 'Goal created';
const String _goalUpdatedMessage = 'Goal updated';

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

  final result = await showDialog<_GoalEditorResult>(
    context: context,
    builder: (_) => _GoalEditorContent(
      existing: existing,
      allGoals: allGoals,
      initialScope: initialScope,
      initialArea: initialArea,
    ),
  );

  if (result == null) return false;

  final service = ref.read(goalServiceProvider);
  final now = DateTime.now();

  final saveResult = existing == null
      ? await service.create(
          Goal(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: planningUserId,
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            scope: result.scope,
            status: result.status,
            targetDate: result.targetDate,
            parentGoalId: result.parentGoalId,
            area: result.area,
            topicId: topicId ?? existing?.topicId,
          ),
        )
      : await service.update(
          existing.copyWith(
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            scope: result.scope,
            status: result.status,
            targetDate: result.targetDate,
            parentGoalId: result.parentGoalId,
            area: result.area,
            updatedAt: now,
          ),
        );

  if (!context.mounted) return false;
  if (saveResult.isFailure) {
    AppFeedback.showError(context, saveResult.error!);
    return false;
  }

  AppFeedback.showSuccess(context, existing == null ? _goalCreatedMessage : _goalUpdatedMessage);
  ref.invalidate(activeGoalsProvider);
  ref.invalidate(todaysGoalsProvider);
  final resolvedTopicId = topicId ?? existing?.topicId;
  if (resolvedTopicId != null) {
    ref.invalidate(goalsForTopicProvider(resolvedTopicId));
  }

  return true;
}

class _GoalEditorResult {
  _GoalEditorResult({
    required this.title,
    required this.description,
    required this.scope,
    required this.status,
    required this.targetDate,
    required this.parentGoalId,
    required this.area,
  });

  final String title;
  final String description;
  final GoalScope scope;
  final GoalStatus status;
  final DateTime? targetDate;
  final String? parentGoalId;
  final LifeArea? area;
}

class _GoalEditorContent extends StatefulWidget {
  const _GoalEditorContent({
    required this.existing,
    required this.allGoals,
    required this.initialScope,
    required this.initialArea,
  });

  final Goal? existing;
  final List<Goal> allGoals;
  final GoalScope? initialScope;
  final LifeArea? initialArea;

  @override
  State<_GoalEditorContent> createState() => _GoalEditorContentState();
}

class _GoalEditorContentState extends State<_GoalEditorContent> {
  static const String _noParentLabel = 'None';
  static const String _notSetLabel = 'Not set';
  static const String _pickLifeAreaMessage = 'Pick a life area';
  static const String _titleRequiredMessage = 'Title is required';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late GoalScope selectedScope;
  late GoalStatus selectedStatus;
  DateTime? selectedDate;
  String? selectedParentId;
  LifeArea? selectedArea;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    selectedScope = widget.existing?.scope ?? widget.initialScope ?? GoalScope.daily;
    selectedStatus = widget.existing?.status ?? GoalStatus.notStarted;
    selectedDate = widget.existing?.targetDate ?? DateTime.now();
    selectedParentId = widget.existing?.parentGoalId;
    selectedArea = widget.existing?.area ?? widget.initialArea;
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
        _GoalEditorResult(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          scope: selectedScope,
          status: selectedStatus,
          targetDate: selectedDate,
          parentGoalId: selectedParentId,
          area: selectedArea,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: widget.existing == null ? 'New Goal' : 'Edit Goal',
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
            SizedBox(height: spacing.md),
            DropdownButtonFormField<GoalScope>(
              initialValue: selectedScope,
              items: GoalScope.values
                  .map((scope) => DropdownMenuItem(value: scope, child: Text(goalScopeLabel(scope))))
                  .toList(),
              onChanged: (value) => setState(() => selectedScope = value ?? selectedScope),
              decoration: const InputDecoration(labelText: 'Scope'),
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<GoalStatus>(
              initialValue: selectedStatus,
              items: GoalStatus.values
                  .map((status) => DropdownMenuItem(value: status, child: Text(goalStatusLabel(status))))
                  .toList(),
              onChanged: (value) => setState(() => selectedStatus = value ?? selectedStatus),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<String?>(
              initialValue: selectedParentId,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text(_noParentLabel)),
                for (final candidate in widget.allGoals.where((g) => g.id != widget.existing?.id))
                  DropdownMenuItem<String?>(value: candidate.id, child: Text(candidate.title)),
              ],
              onChanged: (value) => setState(() => selectedParentId = value),
              decoration: const InputDecoration(labelText: 'Linked goal (optional)'),
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<LifeArea>(
              initialValue: selectedArea,
              items: LifeArea.values
                  .map((area) => DropdownMenuItem(value: area, child: Text(goalAreaLabel(area))))
                  .toList(),
              onChanged: (value) => setState(() => selectedArea = value),
              validator: (value) => value == null ? _pickLifeAreaMessage : null,
              decoration: const InputDecoration(labelText: 'Life area'),
            ),
            SizedBox(height: spacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Target date'),
              subtitle: Text(selectedDate == null ? _notSetLabel : AppDateFormatter.date(selectedDate!)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (!mounted) return;
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
