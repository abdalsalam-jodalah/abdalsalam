import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/medication.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/health_providers.dart';
import '../services/health_service.dart';
import '../services/medication_service.dart';

const _defaultReminderTime = TimeOfDay(hour: 8, minute: 0);

class MedicationFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/medication-form';
  final Medication? medication;

  const MedicationFormScreen({super.key, this.medication});

  @override
  ConsumerState<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _prescribedByController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _startDate;
  DateTime? _endDate;
  DateTime? _refillDate;
  late List<TimeOfDay> _times;
  late String _frequency;
  late bool _isActive;
  late MedicationTiming _timing;
  late Set<WeekDay> _selectedWeekDays;
  late final MedicationService _service;
  late final HealthService _healthService;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(medicationServiceProvider);
    _healthService = ref.read(healthServiceProvider);

    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _prescribedByController.text = widget.medication!.prescribedBy ?? '';
      _notesController.text = widget.medication!.notes ?? '';
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _refillDate = widget.medication!.refillDate;
      _frequency = widget.medication!.frequency;
      _isActive = widget.medication!.isActive;
      _timing = widget.medication!.timing;
      _selectedWeekDays = widget.medication!.weekDays.toSet();
      _times = widget.medication!.reminderTimes
          .map(_parseReminderTime)
          .whereType<TimeOfDay>()
          .toList();
      if (_times.isEmpty) {
        _times = [_defaultReminderTime];
      }
    } else {
      _startDate = DateTime.now();
      _times = [_defaultReminderTime];
      _frequency = 'Daily';
      _isActive = true;
      _timing = MedicationTiming.anytime;
      _selectedWeekDays = {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseReminderTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveMedication() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final reminderTimes = _times
        .map((time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}')
        .toList();

    final medication = Medication(
      id: widget.medication?.id ?? _uuid.v4(),
      createdAt: widget.medication?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      reminderTimes: reminderTimes,
      prescribedBy: _prescribedByController.text.trim().isEmpty ? null : _prescribedByController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      refillDate: _refillDate,
      displayOrder: widget.medication?.displayOrder ?? 0,
      isActive: _isActive,
      timing: _timing,
      weekDays: _selectedWeekDays.toList(),
    );

    final result = widget.medication == null
        ? await _service.create(medication)
        : await _service.update(medication);

    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }

    final reminderResult = await _healthService.refreshReminders(medication);
    if (!mounted) return;
    if (reminderResult.isFailure) {
      AppFeedback.showError(context, reminderResult.error!);
      Navigator.of(context).pop(true);
      return;
    }

    AppFeedback.showSuccess(context, 'Medication ${widget.medication == null ? 'added' : 'updated'}');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication == null ? 'Add Medication' : 'Edit Medication'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication name',
                  hintText: 'e.g. Vitamin D3',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 1000 IU',
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: tokens.spacing.md),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                items: const ['Daily', 'Twice Daily', 'Three Times Daily', 'Four Times Daily', 'Weekly', 'As Needed']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                      // Auto-populate times based on frequency
                      _times = _getDefaultTimes(value);
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              DropdownButtonFormField<MedicationTiming>(
                initialValue: _timing,
                items: MedicationTiming.values
                    .map((timing) => DropdownMenuItem(
                          value: timing,
                          child: Text(_getTimingLabel(timing)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _timing = value ?? _timing),
                decoration: const InputDecoration(
                  labelText: 'When to take',
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              if (_frequency == 'Weekly') ...[
                SizedBox(height: tokens.spacing.md),
                Text('Select Days', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: tokens.spacing.sm),
                Wrap(
                  spacing: tokens.spacing.sm,
                  runSpacing: tokens.spacing.sm,
                  children: WeekDay.values.map((day) {
                    final isSelected = _selectedWeekDays.contains(day);
                    return FilterChip(
                      label: Text(_getWeekDayLabel(day)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekDays.add(day);
                          } else {
                            _selectedWeekDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: tokens.spacing.md),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Currently taking'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Start Date',
                value: _startDate,
                onChanged: (date) {
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.sm),
              DateTimeField(
                label: 'End Date (optional)',
                value: _endDate,
                isClearable: true,
                onChanged: (date) => setState(() => _endDate = date),
              ),
              SizedBox(height: tokens.spacing.sm),
              DateTimeField(
                label: 'Refill Date (optional)',
                value: _refillDate,
                isClearable: true,
                onChanged: (date) => setState(() => _refillDate = date),
              ),
              SizedBox(height: tokens.spacing.lg),
              Text('Reminder Times', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: tokens.spacing.sm),
              Text(
                'Add multiple times for multiple daily doses',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: tokens.spacing.sm),
              Wrap(
                spacing: tokens.spacing.sm,
                runSpacing: tokens.spacing.sm,
                children: [
                  for (var i = 0; i < _times.length; i++)
                    InputChip(
                      label: Text(_times[i].format(context)),
                      avatar: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _times[i]);
                        if (picked != null && mounted) {
                          setState(() => _times[i] = picked);
                        }
                      },
                      onDeleted: _times.length == 1 ? null : () => setState(() => _times.removeAt(i)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_alarm_outlined),
                    label: const Text('Add Time'),
                    onPressed: () => setState(() => _times.add(const TimeOfDay(hour: 12, minute: 0))),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.lg),
              TextFormField(
                controller: _prescribedByController,
                decoration: const InputDecoration(
                  labelText: 'Prescribed By (optional)',
                  hintText: 'Doctor name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Additional info',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              FilledButton.icon(
                onPressed: _saveMedication,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.medication == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimingLabel(MedicationTiming timing) {
    switch (timing) {
      case MedicationTiming.beforeMeal:
        return 'Before meal';
      case MedicationTiming.withMeal:
        return 'With meal';
      case MedicationTiming.afterMeal:
        return 'After meal';
      case MedicationTiming.beforeBed:
        return 'Before bed';
      case MedicationTiming.anytime:
        return 'Anytime';
    }
  }

  String _getWeekDayLabel(WeekDay day) {
    switch (day) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
      case WeekDay.sunday:
        return 'Sunday';
    }
  }

  List<TimeOfDay> _getDefaultTimes(String frequency) {
    switch (frequency) {
      case 'Daily':
        return [const TimeOfDay(hour: 8, minute: 0)];
      case 'Twice Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      case 'Three Times Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      case 'Four Times Daily':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      case 'Weekly':
      case 'As Needed':
      default:
        return [const TimeOfDay(hour: 8, minute: 0)];
    }
  }
}
