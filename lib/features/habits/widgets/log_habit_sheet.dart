import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/habits/habit.dart';
import '../../../data/models/habits/habit_log.dart';
import '../providers/habits_providers.dart';
import 'habit_style_picker.dart';

const _uuid = Uuid();

Future<void> showLogHabitSheet(BuildContext context, WidgetRef ref, Habit habit) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _LogHabitSheet(habit: habit),
  );
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

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_completedAt));
    if (time == null) {
      return;
    }
    setState(() {
      _completedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.isSuccess ? 'Logged' : 'Something went wrong'),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
    if (result.isSuccess) {
      Navigator.of(context).pop();
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit.isGoodHabit ? 'Log occurrence' : 'Log incident',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('When'),
              subtitle: Text('${_completedAt.toLocal()}'.split('.').first),
              onTap: _pickDateTime,
            ),
            if (widget.habit.isGoodHabit) ...[
              const SizedBox(height: 8),
              Text('Mood', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kHabitMoodLabels.map((label) {
                  return ChoiceChip(
                    label: Text(label),
                    selected: _mood == label,
                    onSelected: (selected) => setState(() => _mood = selected ? label : null),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Value (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _situationController,
                decoration: const InputDecoration(labelText: 'Situation', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _causeController,
                decoration: const InputDecoration(labelText: 'Cause', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _triggerController,
                decoration: const InputDecoration(labelText: 'Trigger', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thoughtsBeforeController,
                decoration: const InputDecoration(labelText: 'Thoughts before', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _thoughtsAfterController,
                decoration: const InputDecoration(labelText: 'Thoughts after', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Text('Intensity: $_intensity', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_intensity',
                onChanged: (value) => setState(() => _intensity = value.round()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recoveryActionController,
                decoration: const InputDecoration(labelText: 'Recovery action', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save log'),
            ),
          ],
        ),
      ),
    );
  }
}
