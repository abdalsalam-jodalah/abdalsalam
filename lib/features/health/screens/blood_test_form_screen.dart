import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/blood_test.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/health_providers.dart';
import '../services/blood_test_service.dart';

class BloodTestFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/blood-tests/form';
  final BloodTest? test;

  const BloodTestFormScreen({super.key, this.test});

  @override
  ConsumerState<BloodTestFormScreen> createState() => _BloodTestFormScreenState();
}

class _BloodTestFormScreenState extends ConsumerState<BloodTestFormScreen> {
  static const String _resultValueRequiredMessage = 'Value is required';

  final _formKey = GlobalKey<FormState>();
  final _testTypeController = TextEditingController();
  final _notesController = TextEditingController();
  final _facilityController = TextEditingController();
  late DateTime _scheduledDate;
  DateTime? _completedDate;
  DateTime? _nextTestDate;
  late List<_ResultEntry> _results;
  late final BloodTestService _service;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(bloodTestServiceProvider);

    if (widget.test != null) {
      final test = widget.test!;
      _testTypeController.text = test.testType;
      _notesController.text = test.notes ?? '';
      _facilityController.text = test.facility ?? '';
      _scheduledDate = test.scheduledDate;
      _completedDate = test.completedDate;
      _nextTestDate = test.nextTestDate;
      _results = test.results.entries
          .map((entry) => _ResultEntry(entry.key, entry.value.toString()))
          .toList();
    } else {
      _scheduledDate = DateTime.now();
      _results = [];
    }
  }

  @override
  void dispose() {
    _testTypeController.dispose();
    _notesController.dispose();
    _facilityController.dispose();
    for (final result in _results) {
      result.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final results = <String, dynamic>{
      for (final entry in _results)
        if (entry.keyController.text.trim().isNotEmpty) entry.keyController.text.trim(): entry.valueController.text.trim(),
    };

    final test = BloodTest(
      id: widget.test?.id ?? _uuid.v4(),
      createdAt: widget.test?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      testType: _testTypeController.text.trim(),
      scheduledDate: _scheduledDate,
      completedDate: _completedDate,
      results: results,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      nextTestDate: _nextTestDate,
      facility: _facilityController.text.trim().isEmpty ? null : _facilityController.text.trim(),
    );

    final result = widget.test == null ? await _service.create(test) : await _service.update(test);

    if (!mounted) return;
    if (result.isSuccess) {
      AppFeedback.showSuccess(context, 'Blood test ${widget.test == null ? 'added' : 'updated'}');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test == null ? 'Add Blood Test' : 'Edit Blood Test'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _testTypeController,
                decoration: const InputDecoration(
                  labelText: 'Test type',
                  hintText: 'e.g. CBC, Lipid Panel',
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Scheduled date',
                value: _scheduledDate,
                onChanged: (date) {
                  if (date != null) {
                    setState(() => _scheduledDate = date);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.sm),
              DateTimeField(
                label: 'Completed date (optional)',
                value: _completedDate,
                isClearable: true,
                onChanged: (date) => setState(() => _completedDate = date),
              ),
              SizedBox(height: tokens.spacing.sm),
              DateTimeField(
                label: 'Next test date (optional)',
                value: _nextTestDate,
                isClearable: true,
                onChanged: (date) => setState(() => _nextTestDate = date),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _facilityController,
                decoration: const InputDecoration(
                  labelText: 'Facility (optional)',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Results', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              ..._results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: result.keyController,
                          decoration: const InputDecoration(labelText: 'Test name'),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: result.valueController,
                          decoration: const InputDecoration(labelText: 'Value'),
                          validator: (value) =>
                              result.keyController.text.trim().isNotEmpty && (value == null || value.trim().isEmpty)
                                  ? _resultValueRequiredMessage
                                  : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          result.dispose();
                          _results.removeAt(index);
                        }),
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => setState(() => _results.add(_ResultEntry('', ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add result'),
              ),
              SizedBox(height: tokens.spacing.lg),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.test == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _ResultEntry(String key, String value)
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
