import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';

class SportsAddSetResult {
  SportsAddSetResult(this.reps, this.weight);

  final int reps;
  final double? weight;
}

Future<SportsAddSetResult?> showSportsAddSetDialog(BuildContext context) {
  return showDialog<SportsAddSetResult>(
    context: context,
    builder: (_) => const _AddSetDialogContent(),
  );
}

class _AddSetDialogContent extends StatefulWidget {
  const _AddSetDialogContent();

  @override
  State<_AddSetDialogContent> createState() => _AddSetDialogContentState();
}

class _AddSetDialogContentState extends State<_AddSetDialogContent> {
  static const String _title = 'Add Set';
  static const String _submitLabel = 'Add';
  static const String _requiredMessage = 'Required';
  static const String _mustBeNumberMessage = 'Must be a number';

  final _formKey = GlobalKey<FormState>();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String? _validateOptionalWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value) == null ? _mustBeNumberMessage : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.pop(
      context,
      SportsAddSetResult(int.parse(_repsController.text), double.tryParse(_weightController.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AppFormDialog(
      title: _title,
      submitLabel: _submitLabel,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
              validator: (value) => (value == null || int.tryParse(value) == null) ? _requiredMessage : null,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg, optional)'),
              validator: _validateOptionalWeight,
            ),
          ],
        ),
      ),
    );
  }
}
