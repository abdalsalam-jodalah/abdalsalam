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
  final result = await showDialog<_NoteDialogResult>(
    context: context,
    builder: (_) => _NoteDialogContent(existing: existing),
  );

  if (result == null) return false;

  final service = ref.read(notesServiceProvider);
  final now = DateTime.now();

  final saveResult = existing == null
      ? await service.create(
          Note(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
            userId: notesUserId,
            title: result.title,
            content: result.content,
            tags: const [],
            categoryId: null,
            pinned: false,
            archived: false,
            attachments: const [],
            color: null,
            order: order,
          ),
        )
      : await service.update(existing.copyWith(title: result.title, content: result.content, updatedAt: now));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saveResult.isSuccess ? (existing == null ? 'Note created' : 'Note updated') : 'Something went wrong',
        ),
        backgroundColor: saveResult.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  ref.invalidate(activeNotesProvider);
  return saveResult.isSuccess;
}

class _NoteDialogResult {
  _NoteDialogResult(this.title, this.content);

  final String title;
  final String content;
}

class _NoteDialogContent extends StatefulWidget {
  const _NoteDialogContent({this.existing});

  final Note? existing;

  @override
  State<_NoteDialogContent> createState() => _NoteDialogContentState();
}

class _NoteDialogContentState extends State<_NoteDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    contentController = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Note' : 'Edit Note'),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _NoteDialogResult(titleController.text.trim(), contentController.text.trim()),
              );
            }
          },
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
