import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/religious_tracking_providers.dart';

const String _religiousLogSavedMessage = 'Log saved successfully';
const List<String> _prayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

Future<void> showReligiousEntryDialog(
  BuildContext context,
  WidgetRef ref, {
  required ReligiousEntryType type,
  required String defaultTitle,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ReligiousEntryDialogContent(ref: ref, type: type, defaultTitle: defaultTitle),
  );
}

class ReligiousEntryDialogContent extends StatefulWidget {
  final WidgetRef ref;
  final ReligiousEntryType type;
  final String defaultTitle;

  const ReligiousEntryDialogContent({
    super.key,
    required this.ref,
    required this.type,
    required this.defaultTitle,
  });

  @override
  State<ReligiousEntryDialogContent> createState() => _ReligiousEntryDialogContentState();
}

class _ReligiousEntryDialogContentState extends State<ReligiousEntryDialogContent> {
  static const String _countFieldKey = 'count';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  final detailsController = TextEditingController();
  final countController = TextEditingController(text: '1');
  String prayerName = _prayerNames.first;
  bool reminderEnabled = false;
  DateTime reminderAt = DateTime.now().add(const Duration(hours: 1));
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.defaultTitle);
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    countController.dispose();
    super.dispose();
  }

  String? _validateCount(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Count');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Count must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Count');
    return positiveError ?? fieldErrors[_countFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final title = titleController.text.trim().isEmpty ? widget.defaultTitle : titleController.text.trim();
    final error = await widget.ref.read(religiousLogsControllerProvider.notifier).addEntry(
          type: widget.type,
          title: title,
          count: int.parse(countController.text.trim()),
          details: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
          prayerName: widget.type == ReligiousEntryType.prayer ? prayerName : null,
          reminderAt: reminderEnabled ? reminderAt : null,
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

    AppFeedback.showSuccess(context, _religiousLogSavedMessage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppFormDialog(
      title: 'Log ${_typeLabel(widget.type)}',
      submitLabel: 'Save',
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: tokens.spacing.sm),
            if (widget.type == ReligiousEntryType.prayer) ...[
              DropdownButtonFormField<String>(
                initialValue: prayerName,
                items: _prayerNames
                    .map((name) => DropdownMenuItem(value: name, child: Text(name.toUpperCase())))
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => prayerName = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Prayer name'),
              ),
              SizedBox(height: tokens.spacing.sm),
            ],
            TextFormField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Count / Number'),
              validator: _validateCount,
            ),
            SizedBox(height: tokens.spacing.sm),
            TextField(
              controller: detailsController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
            ),
            SizedBox(height: tokens.spacing.xs),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add reminder'),
              value: reminderEnabled,
              onChanged: (value) => setState(() => reminderEnabled = value),
            ),
            if (reminderEnabled)
              DateTimeField(
                label: 'Reminder',
                mode: DateTimeFieldMode.dateTime,
                value: reminderAt,
                firstDate: DateTime.now(),
                onChanged: (value) => setState(() => reminderAt = value ?? reminderAt),
              ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return 'Prayer';
      case ReligiousEntryType.quranReading:
        return 'Quran Reading';
      case ReligiousEntryType.badEvent:
        return 'Bad Event';
      case ReligiousEntryType.athkar:
        return 'Athkar';
      case ReligiousEntryType.nightPrayer:
        return 'Night Prayer';
    }
  }
}
