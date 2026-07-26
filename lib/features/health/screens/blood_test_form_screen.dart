import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/health/blood_test.dart';
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

    if (result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blood test ${widget.test == null ? 'added' : 'updated'}')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error?.message ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test == null ? 'Add Blood Test' : 'Edit Blood Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _testTypeController,
                decoration: const InputDecoration(
                  labelText: 'Test type',
                  hintText: 'e.g. CBC, Lipid Panel',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Scheduled date',
                date: _scheduledDate,
                onPick: (date) => setState(() => _scheduledDate = date),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'Completed date (optional)',
                date: _completedDate,
                onPick: (date) => setState(() => _completedDate = date),
                onClear: () => setState(() => _completedDate = null),
              ),
              const SizedBox(height: 8),
              _DateField(
                label: 'Next test date (optional)',
                date: _nextTestDate,
                onPick: (date) => setState(() => _nextTestDate = date),
                onClear: () => setState(() => _nextTestDate = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _facilityController,
                decoration: const InputDecoration(
                  labelText: 'Facility (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Results', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._results.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: result.keyController,
                          decoration: const InputDecoration(labelText: 'Test name', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: result.valueController,
                          decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),
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

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final text = date == null
        ? 'Not set'
        : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(label),
      subtitle: Text(text),
      trailing: date != null && onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            )
          : null,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
    );
  }
}
