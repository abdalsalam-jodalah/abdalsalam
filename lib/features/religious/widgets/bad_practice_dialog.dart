import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/bad_practice_providers.dart';

Future<void> showBadPracticeDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => BadPracticeDialogContent(ref: ref),
  );
}

class BadPracticeDialogContent extends StatefulWidget {
  const BadPracticeDialogContent({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<BadPracticeDialogContent> createState() => _BadPracticeDialogContentState();
}

class _BadPracticeDialogContentState extends State<BadPracticeDialogContent> {
  static const String _titleFieldKey = 'title';

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final feelingBeforeController = TextEditingController();
  final feelingAfterController = TextEditingController();
  final consequencesController = TextEditingController();
  final notesController = TextEditingController();
  DateTime occurredAt = DateTime.now();
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  @override
  void dispose() {
    titleController.dispose();
    feelingBeforeController.dispose();
    feelingAfterController.dispose();
    consequencesController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'What happened');
    return requiredError ?? fieldErrors[_titleFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(badPracticeLogControllerProvider.notifier).logEvent(
          title: titleController.text.trim(),
          occurredAt: occurredAt,
          feelingBefore: feelingBeforeController.text.trim().isEmpty ? null : feelingBeforeController.text.trim(),
          feelingAfter: feelingAfterController.text.trim().isEmpty ? null : feelingAfterController.text.trim(),
          consequences: consequencesController.text.trim().isEmpty ? null : consequencesController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        isSaving = false;
        fieldErrors = error is ValidationError ? error.fieldErrors : const <String, String>{};
      });
      _formKey.currentState!.validate();
      AppFeedback.showError(context, error);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppFormDialog(
      title: 'Log Bad Practice',
      submitLabel: 'Save',
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'What happened'),
              validator: _validateTitle,
            ),
            SizedBox(height: tokens.spacing.md),
            DateTimeField(
              label: 'Occurred at',
              mode: DateTimeFieldMode.dateTime,
              value: occurredAt,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              onChanged: (value) => setState(() => occurredAt = value ?? occurredAt),
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: feelingBeforeController,
              decoration: const InputDecoration(labelText: 'Feeling before (optional)'),
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: feelingAfterController,
              decoration: const InputDecoration(labelText: 'Feeling after (optional)'),
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: consequencesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Consequences (optional)'),
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}
