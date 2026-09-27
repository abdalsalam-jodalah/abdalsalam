import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/quran_reading_providers.dart';

Future<void> showQuranReadingDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => QuranReadingDialogContent(ref: ref),
  );
}

class QuranReadingDialogContent extends StatefulWidget {
  const QuranReadingDialogContent({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<QuranReadingDialogContent> createState() => _QuranReadingDialogContentState();
}

class _QuranReadingDialogContentState extends State<QuranReadingDialogContent> {
  static const String _surahFieldKey = 'surahNumber';
  static const String _ayahToFieldKey = 'ayahTo';
  static const String _pagesFieldKey = 'pagesRead';
  static const String _minutesFieldKey = 'durationMinutes';
  static const int _minSurahNumber = 1;
  static const int _maxSurahNumber = 114;

  final _formKey = GlobalKey<FormState>();
  final surahController = TextEditingController();
  final ayahFromController = TextEditingController();
  final ayahToController = TextEditingController();
  final durationController = TextEditingController();
  final pagesController = TextEditingController();
  final placeController = TextEditingController();
  var memorized = false;
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  @override
  void dispose() {
    surahController.dispose();
    ayahFromController.dispose();
    ayahToController.dispose();
    durationController.dispose();
    pagesController.dispose();
    placeController.dispose();
    super.dispose();
  }

  String? _validateSurah(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Surah number');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Surah number must be a whole number';
    final rangeError = ValidationUtils.numericRange(
      value: parsed,
      fieldName: 'Surah number',
      min: _minSurahNumber,
      max: _maxSurahNumber,
    );
    return rangeError ?? fieldErrors[_surahFieldKey];
  }

  String? _validateAyahFrom(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Ayah from');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Ayah from must be a whole number';
    return ValidationUtils.positiveNumber(value: parsed, fieldName: 'Ayah from');
  }

  String? _validateAyahTo(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Ayah to');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Ayah to must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Ayah to');
    if (positiveError != null) return positiveError;
    final ayahFrom = int.tryParse(ayahFromController.text.trim());
    if (ayahFrom != null && parsed < ayahFrom) {
      return 'Ayah to must be at least ayah from';
    }
    return fieldErrors[_ayahToFieldKey];
  }

  String? _validatePages(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Pages read');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Pages read must be a whole number';
    final rangeError = ValidationUtils.numericRange(value: parsed, fieldName: 'Pages read', min: 0);
    return rangeError ?? fieldErrors[_pagesFieldKey];
  }

  String? _validateMinutes(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Minutes spent');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Minutes spent must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Minutes spent');
    return positiveError ?? fieldErrors[_minutesFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(quranReadingControllerProvider.notifier).addReading(
          surahNumber: int.parse(surahController.text.trim()),
          ayahFrom: int.parse(ayahFromController.text.trim()),
          ayahTo: int.parse(ayahToController.text.trim()),
          durationMinutes: int.parse(durationController.text.trim()),
          pagesRead: int.parse(pagesController.text.trim()),
          memorized: memorized,
          place: placeController.text.trim().isEmpty ? null : placeController.text.trim(),
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
      title: 'Add Quran Reading',
      submitLabel: 'Save',
      isSubmitting: isSaving,
      onSubmit: _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: surahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Surah number (1-114)'),
              validator: _validateSurah,
            ),
            SizedBox(height: tokens.spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ayahFromController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayah from'),
                    validator: _validateAyahFrom,
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: TextFormField(
                    controller: ayahToController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayah to'),
                    validator: _validateAyahTo,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pages read'),
              validator: _validatePages,
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes spent'),
              validator: _validateMinutes,
            ),
            SizedBox(height: tokens.spacing.md),
            TextField(
              controller: placeController,
              decoration: const InputDecoration(labelText: 'Place (optional)'),
            ),
            SizedBox(height: tokens.spacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Memorized this range'),
              value: memorized,
              onChanged: (value) => setState(() => memorized = value),
            ),
          ],
        ),
      ),
    );
  }
}
