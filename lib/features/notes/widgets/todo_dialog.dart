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
  final result = await showDialog<_TodoDialogResult>(
    context: context,
    builder: (_) => _TodoDialogContent(existing: existing),
  );

  if (result == null) return false;

  final repo = ref.read(todoRepositoryProvider);
  final now = DateTime.now();

  final saveResult = existing == null
      ? await repo.create(
          Todo(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: notesUserId,
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            dueDate: null,
            priority: TodoPriority.medium,
            status: TodoStatus.pending,
            categoryId: null,
            tags: const [],
            reminderAt: null,
            parentTodoId: null,
            order: order,
            habitId: result.linkedHabitId,
          ),
        )
      : await repo.update(
          existing.copyWith(
            title: result.title,
            description: result.description.isEmpty ? null : result.description,
            updatedAt: now,
            habitId: result.linkedHabitId,
          ),
        );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saveResult.isSuccess ? (existing == null ? 'Todo created' : 'Todo updated') : 'Something went wrong',
        ),
        backgroundColor: saveResult.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  ref.invalidate(activeTodosProvider);
  return saveResult.isSuccess;
}

class _TodoDialogResult {
  _TodoDialogResult(this.title, this.description, this.linkedHabitId);

  final String title;
  final String description;
  final String? linkedHabitId;
}

class _TodoDialogContent extends StatefulWidget {
  const _TodoDialogContent({this.existing});

  final Todo? existing;

  @override
  State<_TodoDialogContent> createState() => _TodoDialogContentState();
}

class _TodoDialogContentState extends State<_TodoDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Todo' : 'Edit Todo'),
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
                          final habit = await Navigator.of(context).push<Habit?>(
                            MaterialPageRoute(
                              builder: (_) => HabitFormScreen(
                                prefillTitle: titleController.text.trim(),
                                prefillDescription: descriptionController.text.trim(),
                              ),
                            ),
                          );
                          if (habit != null) {
                            setState(() => linkedHabitId = habit.id);
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _TodoDialogResult(titleController.text.trim(), descriptionController.text.trim(), linkedHabitId),
              );
            }
          },
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
