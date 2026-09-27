import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/notes/todo.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../habits/screens/habit_form_screen.dart';
import '../providers/notes_providers.dart';

const _uuid = Uuid();

/// Shows the add/edit form for a [Todo] (label + body) and persists the result.
Future<bool> showTodoDialog(
  BuildContext context,
  WidgetRef ref, {
  Todo? existing,
  int order = 0,
}) async {
  final service = ref.read(todoServiceProvider);

  Future<AppError?> saveTodo(String title, String description, String? linkedHabitId) async {
    final now = DateTime.now();
    final normalizedDescription = description.isEmpty ? null : description;
    if (existing == null) {
      final createResult = await service.create(
        Todo(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: notesUserId,
          title: title,
          description: normalizedDescription,
          dueDate: null,
          priority: TodoPriority.medium,
          status: TodoStatus.pending,
          categoryId: null,
          tags: const [],
          reminderAt: null,
          parentTodoId: null,
          order: order,
          habitId: linkedHabitId,
        ),
      );
      return createResult.error;
    }
    final updateResult = await service.update(
      existing.copyWith(
        title: title,
        description: normalizedDescription,
        updatedAt: now,
        habitId: linkedHabitId,
      ),
    );
    return updateResult.error;
  }

  final isSaved = await showDialog<bool>(
        context: context,
        builder: (_) => _TodoDialogContent(existing: existing, onSave: saveTodo),
      ) ??
      false;

  if (isSaved && context.mounted) {
    AppFeedback.showSuccess(context, existing == null ? 'Todo created' : 'Todo updated');
    ref.invalidate(activeTodosProvider);
  }
  return isSaved;
}

class _TodoDialogContent extends StatefulWidget {
  const _TodoDialogContent({this.existing, required this.onSave});

  final Todo? existing;
  final Future<AppError?> Function(String title, String description, String? linkedHabitId) onSave;

  @override
  State<_TodoDialogContent> createState() => _TodoDialogContentState();
}

class _TodoDialogContentState extends State<_TodoDialogContent> {
  static const String _newTodoTitle = 'New Todo';
  static const String _editTodoTitle = 'Edit Todo';
  static const String _createLabel = 'Create';
  static const String _saveLabel = 'Save';
  static const String _labelFieldLabel = 'Label';
  static const String _bodyFieldLabel = 'Body (optional)';
  static const String _labelRequiredMessage = 'Label is required';
  static const String _linkedToHabitLabel = 'Linked to habit';
  static const String _markAsHabitLabel = 'Mark as habit';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  bool isSaving = false;
  String? linkedHabitId;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    linkedHabitId = widget.existing?.habitId;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);
    final error = await widget.onSave(titleController.text.trim(), descriptionController.text.trim(), linkedHabitId);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => isSaving = false);
    AppFeedback.showError(context, error);
  }

  Future<void> _linkHabit() async {
    final habit = await Navigator.of(context).push<Habit?>(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(
          prefillTitle: titleController.text.trim(),
          prefillDescription: descriptionController.text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    if (habit != null) {
      setState(() => linkedHabitId = habit.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppFormDialog(
      title: widget.existing == null ? _newTodoTitle : _editTodoTitle,
      submitLabel: widget.existing == null ? _createLabel : _saveLabel,
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: _labelFieldLabel),
              validator: (value) => (value == null || value.trim().isEmpty) ? _labelRequiredMessage : null,
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: _bodyFieldLabel),
            ),
            SizedBox(height: tokens.spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: linkedHabitId != null ? null : _linkHabit,
                icon: Icon(linkedHabitId != null ? Icons.link : Icons.link_outlined),
                label: Text(linkedHabitId != null ? _linkedToHabitLabel : _markAsHabitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
