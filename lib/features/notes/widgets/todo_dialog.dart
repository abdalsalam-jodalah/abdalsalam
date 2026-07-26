import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/habits/habit.dart';
import '../../../data/models/notes/todo.dart';
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
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  String? linkedHabitId = existing?.habitId;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'New Todo' : 'Edit Todo'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Label is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Body (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: linkedHabitId != null
                        ? null
                        : () async {
                            final habit = await Navigator.of(dialogContext).push<Habit?>(
                              MaterialPageRoute(
                                builder: (_) => HabitFormScreen(
                                  prefillTitle: titleController.text.trim(),
                                  prefillDescription: descriptionController.text.trim(),
                                ),
                              ),
                            );
                            if (habit != null) {
                              setDialogState(() => linkedHabitId = habit.id);
                            }
                          },
                    icon: Icon(linkedHabitId != null ? Icons.link : Icons.link_outlined),
                    label: Text(linkedHabitId != null ? 'Linked to habit' : 'Mark as habit'),
                  ),
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

  final repo = ref.read(todoRepositoryProvider);
  final now = DateTime.now();

  final result = existing == null
      ? await repo.create(
          Todo(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: notesUserId,
            title: title,
            description: description.isEmpty ? null : description,
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
        )
      : await repo.update(
          existing.copyWith(
            title: title,
            description: description.isEmpty ? null : description,
            updatedAt: now,
            habitId: linkedHabitId,
          ),
        );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? (existing == null ? 'Todo created' : 'Todo updated') : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  ref.invalidate(activeTodosProvider);
  return result.isSuccess;
}
