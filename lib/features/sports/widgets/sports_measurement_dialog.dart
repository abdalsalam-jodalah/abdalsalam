import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/body_measurement.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../providers/sports_providers.dart';

const _uuid = Uuid();

Future<void> showSportsMeasurementDialog(
  BuildContext context, {
  required WidgetRef ref,
  double? lastHeight,
}) async {
  final result = await showDialog<_MeasurementDialogResult>(
    context: context,
    builder: (_) => _MeasurementDialogContent(lastHeight: lastHeight),
  );

  if (result == null || !context.mounted) {
    return;
  }

  final service = ref.read(bodyMeasurementServiceProvider);
  final now = DateTime.now();
  final createResult = await service.create(
    BodyMeasurement(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: sportUserId,
      date: dateOnly(now),
      weightKg: result.weight,
      heightCm: result.height,
      bodyFatPercent: result.bodyFat,
      chestCm: result.chest,
      waistCm: result.waist,
      abdominalCm: result.abdominal,
      hipsCm: result.hips,
      thighCm: result.thigh,
      armCm: result.arm,
    ),
  );
  if (!context.mounted) {
    return;
  }
  if (createResult.isFailure) {
    AppFeedback.showError(context, createResult.error!);
  }
  ref.invalidate(bodyMeasurementsInRangeProvider);
}

class _MeasurementDialogResult {
  _MeasurementDialogResult({
    required this.weight,
    required this.height,
    required this.bodyFat,
    required this.chest,
    required this.waist,
    required this.abdominal,
    required this.hips,
    required this.thigh,
    required this.arm,
  });

  final double weight;
  final double? height;
  final double? bodyFat;
  final double? chest;
  final double? waist;
  final double? abdominal;
  final double? hips;
  final double? thigh;
  final double? arm;
}

class _MeasurementDialogContent extends StatefulWidget {
  const _MeasurementDialogContent({required this.lastHeight});

  final double? lastHeight;

  @override
  State<_MeasurementDialogContent> createState() => _MeasurementDialogContentState();
}

class _MeasurementDialogContentState extends State<_MeasurementDialogContent> {
  static const String _title = 'Log Body Measurements';
  static const String _submitLabel = 'Save';
  static const String _requiredMessage = 'Required';
  static const String _mustBeNumberMessage = 'Must be a number';
  static const String _circumferenceLabel = 'Circumference (cm, optional)';

  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  late final TextEditingController _heightController;
  final _bodyFatController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _abdominalController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighController = TextEditingController();
  final _armController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.lastHeight?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _abdominalController.dispose();
    _hipsController.dispose();
    _thighController.dispose();
    _armController.dispose();
    super.dispose();
  }

  String? _validateOptionalPositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _mustBeNumberMessage;
    }
    return ValidationUtils.positiveNumber(value: parsed, fieldName: fieldName);
  }

  String? _validateBodyFatPercent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _mustBeNumberMessage;
    }
    return ValidationUtils.numericRange(value: parsed, fieldName: 'Body fat %', min: 0, max: 100);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.pop(
      context,
      _MeasurementDialogResult(
        weight: double.parse(_weightController.text),
        height: double.tryParse(_heightController.text),
        bodyFat: double.tryParse(_bodyFatController.text),
        chest: double.tryParse(_chestController.text),
        waist: double.tryParse(_waistController.text),
        abdominal: double.tryParse(_abdominalController.text),
        hips: double.tryParse(_hipsController.text),
        thigh: double.tryParse(_thighController.text),
        arm: double.tryParse(_armController.text),
      ),
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
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              validator: (value) => (value == null || double.tryParse(value) == null) ? _requiredMessage : null,
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Height (cm, one-time)'),
              validator: (value) => _validateOptionalPositiveNumber(value, 'Height'),
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _bodyFatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Body fat % (optional)'),
              validator: _validateBodyFatPercent,
            ),
            SizedBox(height: spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_circumferenceLabel, style: Theme.of(context).textTheme.titleSmall),
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _chestController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Chest'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Chest'),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _waistController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Waist'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Waist'),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _abdominalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Abdominal'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Abdominal'),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _hipsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Hips'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Hips'),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _thighController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Leg (thigh)'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Thigh'),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _armController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Arm'),
                    validator: (value) => _validateOptionalPositiveNumber(value, 'Arm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
