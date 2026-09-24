import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/notes/note.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/notes_providers.dart';

const _uuid = Uuid();

/// Shows the add/edit form for a [Note] (label + body) and persists the result.
Future<bool> showNoteDialog(
  BuildContext context,
  WidgetRef ref, {
  Note? existing,
  int order = 0,
}) async {
  final service = ref.read(notesServiceProvider);

  Future<AppError?> saveNote(String title, String content) async {
    final now = DateTime.now();
    if (existing == null) {
      final createResult = await service.create(
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
      );
      return createResult.error;
    }
    final updateResult = await service.update(existing.copyWith(title: title, content: content, updatedAt: now));
    return updateResult.error;
  }

  final isSaved = await showDialog<bool>(
        context: context,
        builder: (_) => _NoteDialogContent(existing: existing, onSave: saveNote),
      ) ??
      false;

  if (isSaved && context.mounted) {
    AppFeedback.showSuccess(context, existing == null ? 'Note created' : 'Note updated');
    ref.invalidate(activeNotesProvider);
  }
  return isSaved;
}

class _NoteDialogContent extends StatefulWidget {
  const _NoteDialogContent({this.existing, required this.onSave});

  final Note? existing;
  final Future<AppError?> Function(String title, String content) onSave;

  @override
  State<_NoteDialogContent> createState() => _NoteDialogContentState();
}

class _NoteDialogContentState extends State<_NoteDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  bool isSaving = false;

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

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);
    final error = await widget.onSave(titleController.text.trim(), contentController.text.trim());
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => isSaving = false);
    AppFeedback.showError(context, error);
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
          onPressed: isSaving ? null : _save,
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
