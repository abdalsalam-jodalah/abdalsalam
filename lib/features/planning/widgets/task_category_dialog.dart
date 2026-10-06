import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/planning/task_category.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../services/task_category_service.dart';
import 'task_category_badge.dart';
import 'task_category_draft.dart';
import 'task_category_palette.dart';
import 'task_category_palette_picker.dart';

Future<TaskCategoryDraft?> showTaskCategoryDialog(
  BuildContext context, {
  TaskCategory? existing,
  Set<String> takenNames = const <String>{},
}) {
  return showDialog<TaskCategoryDraft>(
    context: context,
    builder: (_) => TaskCategoryDialog(existing: existing, takenNames: takenNames),
  );
}

class TaskCategoryDialog extends StatefulWidget {
  final TaskCategory? existing;
  final Set<String> takenNames;

  const TaskCategoryDialog({super.key, this.existing, this.takenNames = const <String>{}});

  @override
  State<TaskCategoryDialog> createState() => _TaskCategoryDialogState();
}

class _TaskCategoryDialogState extends State<TaskCategoryDialog> {
  static const String _nameRequiredMessage = 'Name is required';
  static const String _nameTakenMessage = 'A category with this name already exists';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController = TextEditingController(text: widget.existing?.name ?? '');
  late String selectedColor = widget.existing?.color ?? TaskCategoryPalette.presets[2];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return _nameRequiredMessage;
    if (widget.takenNames.contains(name.toLowerCase())) return _nameTakenMessage;
    return null;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, TaskCategoryDraft(name: nameController.text.trim(), color: selectedColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: widget.existing == null ? 'New category' : 'Edit category',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      onSubmit: _submit,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenableBuilder(
              listenable: nameController,
              builder: (context, _) => Align(
                alignment: Alignment.centerLeft,
                child: TaskCategoryBadge.preview(
                  name: nameController.text.trim().isEmpty ? 'Preview' : nameController.text.trim(),
                  colorHex: selectedColor,
                ),
              ),
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: nameController,
              autofocus: true,
              maxLength: TaskCategoryService.maxNameLength,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.done,
              validator: _validateName,
              onFieldSubmitted: (_) => _submit(),
            ),
            SizedBox(height: spacing.sm),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            SizedBox(height: spacing.sm),
            TaskCategoryPalettePicker(
              selectedColor: selectedColor,
              onChanged: (hex) => setState(() => selectedColor = hex),
            ),
          ],
        ),
      ),
    );
  }
}
