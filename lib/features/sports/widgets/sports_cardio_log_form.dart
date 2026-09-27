import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/sports_providers.dart';

class SportsCardioLogForm extends ConsumerStatefulWidget {
  final ExerciseLog log;

  const SportsCardioLogForm({super.key, required this.log});

  @override
  ConsumerState<SportsCardioLogForm> createState() => _SportsCardioLogFormState();
}

class _SportsCardioLogFormState extends ConsumerState<SportsCardioLogForm> {
  static const String _mustBeWholeNumberMessage = 'Must be a whole number';
  static const String _mustBeNumberMessage = 'Must be a number';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stepsController;
  late final TextEditingController _durationController;
  late final TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: widget.log.steps?.toString() ?? '');
    _durationController = TextEditingController(text: widget.log.durationSeconds?.toString() ?? '');
    _distanceController = TextEditingController(text: widget.log.distanceKm?.toString() ?? '');
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  String? _validateOptionalWholeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return int.tryParse(value) == null ? _mustBeWholeNumberMessage : null;
  }

  String? _validateOptionalDecimal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value) == null ? _mustBeNumberMessage : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final service = ref.read(exerciseLogServiceProvider);
    final updateResult = await service.update(
      widget.log.copyWith(
        steps: int.tryParse(_stepsController.text),
        durationSeconds: int.tryParse(_durationController.text),
        distanceKm: double.tryParse(_distanceController.text),
        updatedAt: DateTime.now(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (updateResult.isFailure) {
      AppFeedback.showError(context, updateResult.error!);
    }
    ref.invalidate(logsForDateProvider(dateOnly(widget.log.date)));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stepsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Steps'),
                validator: _validateOptionalWholeNumber,
                onFieldSubmitted: (_) => _save(),
                onEditingComplete: _save,
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (sec)'),
                validator: _validateOptionalWholeNumber,
                onFieldSubmitted: (_) => _save(),
                onEditingComplete: _save,
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: TextFormField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Distance (km)'),
                validator: _validateOptionalDecimal,
                onFieldSubmitted: (_) => _save(),
                onEditingComplete: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
