import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';

class SportsExerciseDialogResult {
  SportsExerciseDialogResult({
    required this.name,
    required this.instructions,
    required this.equipment,
    required this.defaultSets,
    required this.defaultReps,
    required this.defaultWeight,
    required this.trackingType,
    required this.difficulty,
  });

  final String name;
  final String instructions;
  final String equipment;
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeight;
  final ExerciseTrackingType trackingType;
  final ExerciseDifficulty difficulty;
}

Future<SportsExerciseDialogResult?> showSportsExerciseDialog(BuildContext context, {Exercise? exercise}) {
  return showDialog<SportsExerciseDialogResult>(
    context: context,
    builder: (_) => _ExerciseDialogContent(exercise: exercise),
  );
}

class _ExerciseDialogContent extends StatefulWidget {
  const _ExerciseDialogContent({required this.exercise});

  final Exercise? exercise;

  @override
  State<_ExerciseDialogContent> createState() => _ExerciseDialogContentState();
}

class _ExerciseDialogContentState extends State<_ExerciseDialogContent> {
  static const String _mustBeWholeNumberMessage = 'Must be a whole number';
  static const String _mustBeNumberMessage = 'Must be a number';
  static const String _requiredMessage = 'Required';
  static const String _newTitle = 'New Exercise';
  static const String _editTitle = 'Edit Exercise';
  static const String _createLabel = 'Create';
  static const String _saveLabel = 'Save';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _equipmentController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late ExerciseTrackingType _selectedType;
  late ExerciseDifficulty _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _nameController = TextEditingController(text: exercise?.name ?? '');
    _instructionsController = TextEditingController(text: exercise?.instructions ?? '');
    _equipmentController = TextEditingController(text: exercise?.equipment ?? '');
    _setsController = TextEditingController(text: exercise?.defaultSets?.toString() ?? '');
    _repsController = TextEditingController(text: exercise?.defaultReps?.toString() ?? '');
    _weightController = TextEditingController(text: exercise?.defaultWeightKg?.toString() ?? '');
    _selectedType = exercise?.trackingType ?? ExerciseTrackingType.reps;
    _selectedDifficulty = exercise?.difficulty ?? ExerciseDifficulty.intermediate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _equipmentController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String? _validateOptionalPositiveInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return _mustBeWholeNumberMessage;
    }
    return ValidationUtils.positiveNumber(value: parsed, fieldName: fieldName);
  }

  String? _validateOptionalNonNegativeWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _mustBeNumberMessage;
    }
    return ValidationUtils.numericRange(value: parsed, fieldName: 'Default weight', min: 0);
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(
        context,
        SportsExerciseDialogResult(
          name: _nameController.text.trim(),
          instructions: _instructionsController.text.trim(),
          equipment: _equipmentController.text.trim(),
          defaultSets: int.tryParse(_setsController.text),
          defaultReps: int.tryParse(_repsController.text),
          defaultWeight: double.tryParse(_weightController.text),
          trackingType: _selectedType,
          difficulty: _selectedDifficulty,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final isNew = widget.exercise == null;
    return AppFormDialog(
      title: isNew ? _newTitle : _editTitle,
      submitLabel: isNew ? _createLabel : _saveLabel,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? _requiredMessage : null,
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<ExerciseTrackingType>(
              decoration: const InputDecoration(labelText: 'Tracking'),
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(value: ExerciseTrackingType.reps, child: Text('Sets / Reps / Weight')),
                DropdownMenuItem(value: ExerciseTrackingType.cardio, child: Text('Cardio (steps/duration/distance)')),
              ],
              onChanged: (value) => setState(() => _selectedType = value ?? _selectedType),
            ),
            SizedBox(height: spacing.md),
            DropdownButtonFormField<ExerciseDifficulty>(
              decoration: const InputDecoration(labelText: 'Difficulty'),
              initialValue: _selectedDifficulty,
              items: const [
                DropdownMenuItem(value: ExerciseDifficulty.beginner, child: Text('Beginner')),
                DropdownMenuItem(value: ExerciseDifficulty.intermediate, child: Text('Intermediate')),
                DropdownMenuItem(value: ExerciseDifficulty.advanced, child: Text('Advanced')),
              ],
              onChanged: (value) => setState(() => _selectedDifficulty = value ?? _selectedDifficulty),
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _equipmentController,
              decoration: const InputDecoration(labelText: 'Equipment (optional)'),
            ),
            if (_selectedType == ExerciseTrackingType.reps) ...[
              SizedBox(height: spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Default sets'),
                      validator: (value) => _validateOptionalPositiveInt(value, 'Default sets'),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Default reps'),
                      validator: (value) => _validateOptionalPositiveInt(value, 'Default reps'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Default weight (kg, optional)'),
                validator: _validateOptionalNonNegativeWeight,
              ),
            ],
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Instructions (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}
