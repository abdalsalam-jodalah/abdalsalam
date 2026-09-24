import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/habits/habit.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_style_picker.dart';

const _uuid = Uuid();
const _weekdayLabels = <int, String>{
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

class HabitFormArgs {
  final Habit? existing;
  final String? prefillTitle;
  final String? prefillDescription;

  const HabitFormArgs({this.existing, this.prefillTitle, this.prefillDescription});
}

class HabitFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/habits/form';

  final Habit? existing;
  final String? prefillTitle;
  final String? prefillDescription;

  const HabitFormScreen({super.key, this.existing, this.prefillTitle, this.prefillDescription});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  static const int _maxDescriptionLength = 500;
  static const String _habitCreatedMessage = 'Habit created';
  static const String _habitUpdatedMessage = 'Habit updated';
  static const String _customCategoryRequiredMessage = 'Custom category name is required';
  static const String _descriptionTooLongMessage = 'Description must be $_maxDescriptionLength characters or fewer';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _customBadCategoryController;

  TimeOfDay? _reminderTime;
  TimeOfDay _defaultReminderTime = const TimeOfDay(hour: 8, minute: 0);
  late HabitFrequency _frequency;
  late String _category;
  late bool _isGoodHabit;
  late BadHabitCategory? _badHabitCategory;
  late Set<int> _customWeekdays;
  late String _icon;
  late String _color;
  bool _isSaving = false;

  Habit? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final habit = _existing;
    _nameController = TextEditingController(text: habit?.name ?? widget.prefillTitle ?? '');
    _descriptionController =
        TextEditingController(text: habit?.description ?? widget.prefillDescription ?? '');
    _targetController = TextEditingController(text: (habit?.targetCount ?? 1).toString());
    _customBadCategoryController = TextEditingController(text: habit?.customBadHabitCategoryName ?? '');
    _reminderTime = habit?.reminderTime == null ? null : _parseTimeOfDay(habit!.reminderTime!);
    _frequency = habit?.frequency ?? HabitFrequency.daily;
    _category = habit?.category ?? 'Health';
    _isGoodHabit = habit?.isGoodHabit ?? true;
    _badHabitCategory = habit?.badHabitCategory;
    _customWeekdays = (habit?.customWeekdays ?? const <int>[]).toSet();
    _icon = habit?.icon ?? kDefaultHabitIcon;
    _color = habit?.color ?? kDefaultHabitColor;
    if (habit == null) {
      _loadDefaultReminderTime();
    }
  }

  Future<void> _loadDefaultReminderTime() async {
    final settings = await ref.read(settingsServiceProvider).getSettings();
    final minutes = (settings['habitsDefaultReminderMinutes'] as int?) ?? 480;
    if (mounted) {
      setState(() => _defaultReminderTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _customBadCategoryController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final service = ref.read(habitsServiceProvider);
    final targetCount = int.parse(_targetController.text.trim());
    final customBadName = _badHabitCategory == BadHabitCategory.custom
        ? _customBadCategoryController.text.trim()
        : null;

    final habit = (_existing ??
            Habit(
              id: _uuid.v4(),
              createdAt: now,
              updatedAt: now,
              userId: habitsUserId,
              name: '',
              description: '',
              frequency: HabitFrequency.daily,
              targetCount: 1,
              reminderTime: null,
              icon: kDefaultHabitIcon,
              color: kDefaultHabitColor,
              category: 'Health',
              isGoodHabit: true,
            ))
        .copyWith(
      updatedAt: now,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      frequency: _frequency,
      targetCount: targetCount,
      reminderTime: _reminderTime == null ? null : _formatTimeOfDay(_reminderTime!),
      clearReminderTime: _reminderTime == null,
      icon: _icon,
      color: _color,
      category: _category,
      isGoodHabit: _isGoodHabit,
      badHabitCategory: _isGoodHabit ? null : _badHabitCategory,
      clearBadHabitCategory: _isGoodHabit || _badHabitCategory == null,
      customBadHabitCategoryName: customBadName,
      clearCustomBadHabitCategoryName: customBadName == null || customBadName.isEmpty,
      customWeekdays: _frequency == HabitFrequency.custom ? _customWeekdays.toList() : const <int>[],
      clearCustomWeekdays: _frequency != HabitFrequency.custom,
    );

    final bool isSuccess;
    final AppError? writeError;
    if (_existing == null) {
      final result = await service.create(habit);
      isSuccess = result.isSuccess;
      writeError = result.error;
    } else {
      final result = await service.update(habit);
      isSuccess = result.isSuccess;
      writeError = result.error;
    }

    AppError? reminderError;
    if (isSuccess && _reminderTime != null) {
      final reminderResult = await service.scheduleHabitReminder(habit);
      if (reminderResult.isFailure) {
        reminderError = reminderResult.error;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);

    if (!isSuccess) {
      AppFeedback.showError(context, writeError!);
      return;
    }

    ref.invalidate(activeHabitsProvider);
    if (_existing != null) {
      ref.invalidate(habitByIdProvider(habit.id));
    }

    if (reminderError != null) {
      AppFeedback.showError(context, reminderError);
    } else {
      AppFeedback.showSuccess(context, _existing == null ? _habitCreatedMessage : _habitUpdatedMessage);
    }

    Navigator.of(context).pop(habit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_existing == null ? 'New Habit' : 'Edit Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Read Quran',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Habit name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) =>
                    (value != null && value.trim().length > _maxDescriptionLength) ? _descriptionTooLongMessage : null,
              ),
              const SizedBox(height: 16),
              Text('Is this a good or bad habit?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Good habit'), icon: Icon(Icons.thumb_up_outlined)),
                  ButtonSegment(value: false, label: Text('Bad habit'), icon: Icon(Icons.thumb_down_outlined)),
                ],
                selected: {_isGoodHabit},
                onSelectionChanged: (selection) => setState(() => _isGoodHabit = selection.first),
              ),
              if (!_isGoodHabit) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<BadHabitCategory?>(
                  initialValue: _badHabitCategory,
                  items: [
                    const DropdownMenuItem<BadHabitCategory?>(value: null, child: Text('None')),
                    ...BadHabitCategory.values.map(
                      (category) => DropdownMenuItem(value: category, child: Text(category.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _badHabitCategory = value),
                  decoration:
                      const InputDecoration(labelText: 'Bad habit category', border: OutlineInputBorder()),
                ),
                if (_badHabitCategory == BadHabitCategory.custom) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customBadCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Custom category name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? _customCategoryRequiredMessage : null,
                  ),
                ],
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<HabitFrequency>(
                initialValue: _frequency,
                items: HabitFrequency.values
                    .map((freq) => DropdownMenuItem(value: freq, child: Text(freq.name)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _frequency = value ?? _frequency),
                decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
              ),
              if (_frequency == HabitFrequency.custom) ...[
                const SizedBox(height: 12),
                Text('Repeat on', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _weekdayLabels.entries.map((entry) {
                    final selected = _customWeekdays.contains(entry.key);
                    return FilterChip(
                      label: Text(entry.value),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        if (value) {
                          _customWeekdays.add(entry.key);
                        } else {
                          _customWeekdays.remove(entry.key);
                        }
                      }),
                    );
                  }).toList(growable: false),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target count', border: OutlineInputBorder()),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Target count must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const ['Health', 'Productivity', 'Learning', 'Spiritual', 'Social']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _category = value ?? _category),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text('Icon', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              HabitIconPickerField(selectedIcon: _icon, onChanged: (value) => setState(() => _icon = value)),
              const SizedBox(height: 16),
              Text('Color', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              HabitColorPickerField(
                selectedColorHex: _color,
                onChanged: (value) => setState(() => _color = value),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                leading: const Icon(Icons.alarm_outlined),
                title: const Text('Reminder time'),
                subtitle: Text(_reminderTime == null ? 'Disabled' : _reminderTime!.format(context)),
                trailing: Switch(
                  value: _reminderTime != null,
                  onChanged: (enabled) {
                    setState(() {
                      _reminderTime = enabled ? (_reminderTime ?? _defaultReminderTime) : null;
                    });
                  },
                ),
                onTap: () async {
                  if (_reminderTime == null) {
                    return;
                  }
                  final picked = await showTimePicker(context: context, initialTime: _reminderTime!);
                  if (picked == null || !mounted) {
                    return;
                  }
                  setState(() => _reminderTime = picked);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(_existing == null ? 'Save Habit' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
