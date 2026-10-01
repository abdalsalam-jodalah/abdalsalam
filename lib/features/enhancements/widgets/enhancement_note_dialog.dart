// lib/features/enhancements/widgets/enhancement_note_dialog.dart: add/edit form for an enhancement note.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/enhancements/enhancement_note.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/enhancement_providers.dart';

const _uuid = Uuid();

Future<bool> showEnhancementNoteDialog(
  BuildContext context,
  WidgetRef ref, {
  EnhancementNote? existing,
}) async {
  final service = ref.read(enhancementNoteServiceProvider);

  Future<AppError?> saveNote(String title, String details, EnhancementPriority priority) async {
    final now = DateTime.now();
    final normalizedDetails = details.isEmpty ? null : details;
    if (existing == null) {
      final created = await service.create(
        EnhancementNote(
          id: _uuid.v4(),
          createdAt: now,
          updatedAt: now,
          userId: enhancementUserId,
          title: title,
          details: normalizedDetails,
          priority: priority,
        ),
      );
      return created.error;
    }
    final updated = await service.update(
      existing.copyWith(
        title: title,
        details: normalizedDetails,
        clearDetails: normalizedDetails == null,
        priority: priority,
        updatedAt: now,
      ),
    );
    return updated.error;
  }

  final isSaved = await showDialog<bool>(
        context: context,
        builder: (_) => _EnhancementNoteDialogContent(existing: existing, onSave: saveNote),
      ) ??
      false;

  if (isSaved) {
    ref.invalidate(enhancementNotesProvider);
  }
  return isSaved;
}

class _EnhancementNoteDialogContent extends StatefulWidget {
  const _EnhancementNoteDialogContent({this.existing, required this.onSave});

  final EnhancementNote? existing;
  final Future<AppError?> Function(String title, String details, EnhancementPriority priority) onSave;

  @override
  State<_EnhancementNoteDialogContent> createState() => _EnhancementNoteDialogContentState();
}

class _EnhancementNoteDialogContentState extends State<_EnhancementNoteDialogContent> {
  static const String _newTitle = 'New enhancement note';
  static const String _editTitle = 'Edit enhancement note';
  static const String _createLabel = 'Add';
  static const String _saveLabel = 'Save';
  static const String _titleFieldLabel = 'What should be improved?';
  static const String _detailsFieldLabel = 'Details (optional)';
  static const String _titleRequiredMessage = 'Write what you want to improve';
  static const String _priorityLabel = 'Priority';
  static const int _detailsLines = 5;

  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController detailsController;
  late EnhancementPriority priority;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existing?.title ?? '');
    detailsController = TextEditingController(text: widget.existing?.details ?? '');
    priority = widget.existing?.priority ?? EnhancementPriority.medium;
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);
    final error = await widget.onSave(titleController.text.trim(), detailsController.text.trim(), priority);
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
    final tokens = AppThemeTokens.of(context);
    return AppFormDialog(
      title: widget.existing == null ? _newTitle : _editTitle,
      submitLabel: widget.existing == null ? _createLabel : _saveLabel,
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: _titleFieldLabel),
              validator: (value) => (value == null || value.trim().isEmpty) ? _titleRequiredMessage : null,
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: detailsController,
              maxLines: _detailsLines,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: _detailsFieldLabel, alignLabelWithHint: true),
            ),
            SizedBox(height: tokens.spacing.md),
            Text(_priorityLabel, style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: tokens.spacing.sm),
            SegmentedButton<EnhancementPriority>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: EnhancementPriority.low, label: Text('Low')),
                ButtonSegment(value: EnhancementPriority.medium, label: Text('Medium')),
                ButtonSegment(value: EnhancementPriority.high, label: Text('High')),
              ],
              selected: {priority},
              onSelectionChanged: (selection) => setState(() => priority = selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
