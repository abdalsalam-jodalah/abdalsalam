import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/notes/note.dart';
import '../providers/notes_providers.dart';

const _uuid = Uuid();

/// Shows the add/edit form for a [Note] (label + body) and persists the result.
Future<bool> showNoteDialog(
  BuildContext context,
  WidgetRef ref, {
  Note? existing,
  int order = 0,
}) async {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController(text: existing?.title ?? '');
  final contentController = TextEditingController(text: existing?.content ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(existing == null ? 'New Note' : 'Edit Note'),
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
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()),
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
  );

  if (saved != true) {
    titleController.dispose();
    contentController.dispose();
    return false;
  }

  final title = titleController.text.trim();
  final content = contentController.text.trim();
  titleController.dispose();
  contentController.dispose();

  final repo = ref.read(notesRepositoryProvider);
  final now = DateTime.now();

  final result = existing == null
      ? await repo.create(
          Note(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: notesUserId,
            title: title,
            content: content,
            tags: const [],
            categoryId: null,
            pinned: false,
            archived: false,
            attachments: const [],
            color: null,
            order: order,
          ),
        )
      : await repo.update(existing.copyWith(title: title, content: content, updatedAt: now));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? (existing == null ? 'Note created' : 'Note updated') : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  ref.invalidate(activeNotesProvider);
  return result.isSuccess;
}
