import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';
import '../providers/habits_providers.dart';
import 'habit_style_picker.dart';

const _uuid = Uuid();

Future<void> showLogHabitSheet(BuildContext context, WidgetRef ref, Habit habit) async {
  await showAppBottomSheet<void>(
    context,
    builder: (sheetContext) => _LogHabitSheet(habit: habit),
  );
  if (!context.mounted) {
    return;
  }
  ref.invalidate(logsForHabitProvider(habit.id));
  ref.invalidate(habitStatisticsProvider(habit.id));
}

class _LogHabitSheet extends ConsumerStatefulWidget {
  final Habit habit;

  const _LogHabitSheet({required this.habit});

  @override
  ConsumerState<_LogHabitSheet> createState() => _LogHabitSheetState();
}

class _LogHabitSheetState extends ConsumerState<_LogHabitSheet> {
  static const int _maxFreeTextLength = 500;
  static const String _situationRequiredMessage = 'Situation is required';
  static const String _valueInvalidMessage = 'Value must be a number';
  static const String _loggedMessage = 'Logged';
  static const String _logOccurrenceTitle = 'Log occurrence';
  static const String _logIncidentTitle = 'Log incident';
  static const String _whenLabel = 'When';
  static const String _moodLabel = 'Mood';
  static const String _valueLabel = 'Value (optional)';
  static const String _notesLabel = 'Notes (optional)';
  static const String _situationLabel = 'Situation';
  static const String _causeLabel = 'Cause';
  static const String _triggerLabel = 'Trigger';
  static const String _locationLabel = 'Location';
  static const String _thoughtsBeforeLabel = 'Thoughts before';
  static const String _thoughtsAfterLabel = 'Thoughts after';
  static const String _recoveryActionLabel = 'Recovery action';
  static const String _intensityLabelPrefix = 'Intensity: ';
  static const String _saveLogLabel = 'Save log';
  static const int _minIntensity = 1;
  static const int _maxIntensity = 5;
  static const int _intensityDivisions = 4;

  final _formKey = GlobalKey<FormState>();
  DateTime _completedAt = DateTime.now();
  final _notesController = TextEditingController();
  final _valueController = TextEditingController();
  String? _mood;

  final _situationController = TextEditingController();
  final _causeController = TextEditingController();
  final _triggerController = TextEditingController();
  final _locationController = TextEditingController();
  final _thoughtsBeforeController = TextEditingController();
  final _thoughtsAfterController = TextEditingController();
  final _recoveryActionController = TextEditingController();
  int _intensity = 3;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    _valueController.dispose();
    _situationController.dispose();
    _causeController.dispose();
    _triggerController.dispose();
    _locationController.dispose();
    _thoughtsBeforeController.dispose();
    _thoughtsAfterController.dispose();
    _recoveryActionController.dispose();
    super.dispose();
  }

  String? _optionalTextValidator(String? value) {
    if (value != null && value.trim().length > _maxFreeTextLength) {
      return 'Must be $_maxFreeTextLength characters or fewer';
    }
    return null;
  }

  String? _situationValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _situationRequiredMessage;
    }
    return _optionalTextValidator(value);
  }

  String? _valueValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (double.tryParse(value.trim()) == null) {
      return _valueInvalidMessage;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final log = HabitLog(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      userId: habitsUserId,
      habitId: widget.habit.id,
      completedAt: _completedAt,
      value: double.tryParse(_valueController.text.trim()),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      mood: widget.habit.isGoodHabit ? _mood : null,
      situation: widget.habit.isGoodHabit ? null : _emptyToNull(_situationController.text),
      cause: widget.habit.isGoodHabit ? null : _emptyToNull(_causeController.text),
      trigger: widget.habit.isGoodHabit ? null : _emptyToNull(_triggerController.text),
      location: widget.habit.isGoodHabit ? null : _emptyToNull(_locationController.text),
      thoughtsBefore: widget.habit.isGoodHabit ? null : _emptyToNull(_thoughtsBeforeController.text),
      thoughtsAfter: widget.habit.isGoodHabit ? null : _emptyToNull(_thoughtsAfterController.text),
      intensity: widget.habit.isGoodHabit ? null : _intensity,
      recoveryAction: widget.habit.isGoodHabit ? null : _emptyToNull(_recoveryActionController.text),
    );

    final result = await ref.read(habitLogServiceProvider).create(log);

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }

    AppFeedback.showSuccess(context, _loggedMessage);
    Navigator.of(context).pop();
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit.isGoodHabit ? _logOccurrenceTitle : _logIncidentTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: tokens.spacing.md),
            DateTimeField(
              label: _whenLabel,
              value: _completedAt,
              mode: DateTimeFieldMode.dateTime,
              lastDate: DateTime.now(),
              onChanged: (value) => setState(() => _completedAt = value ?? _completedAt),
            ),
            if (widget.habit.isGoodHabit) ...[
              SizedBox(height: tokens.spacing.sm),
              Text(_moodLabel, style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: tokens.spacing.sm),
              Wrap(
                spacing: tokens.spacing.sm,
                children: kHabitMoodLabels.map((label) {
                  return ChoiceChip(
                    label: Text(label),
                    selected: _mood == label,
                    onSelected: (selected) => setState(() => _mood = selected ? label : null),
                  );
                }).toList(growable: false),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: _valueLabel),
                validator: _valueValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: _notesLabel),
                validator: _optionalTextValidator,
              ),
            ] else ...[
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _situationController,
                decoration: const InputDecoration(labelText: _situationLabel),
                validator: _situationValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _causeController,
                decoration: const InputDecoration(labelText: _causeLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _triggerController,
                decoration: const InputDecoration(labelText: _triggerLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: _locationLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _thoughtsBeforeController,
                decoration: const InputDecoration(labelText: _thoughtsBeforeLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _thoughtsAfterController,
                decoration: const InputDecoration(labelText: _thoughtsAfterLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              Text('$_intensityLabelPrefix$_intensity', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _intensity.toDouble(),
                min: _minIntensity.toDouble(),
                max: _maxIntensity.toDouble(),
                divisions: _intensityDivisions,
                label: '$_intensity',
                onChanged: (value) => setState(() => _intensity = value.round()),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _recoveryActionController,
                decoration: const InputDecoration(labelText: _recoveryActionLabel),
                validator: _optionalTextValidator,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: _notesLabel),
                validator: _optionalTextValidator,
              ),
            ],
            SizedBox(height: tokens.spacing.lg),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text(_saveLogLabel),
            ),
          ],
        ),
      ),
    );
  }
}
