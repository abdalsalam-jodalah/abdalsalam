import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class HabitsSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/habits';

  const HabitsSettingsScreen({super.key});

  @override
  ConsumerState<HabitsSettingsScreen> createState() => _HabitsSettingsScreenState();
}

class _HabitsSettingsScreenState extends ConsumerState<HabitsSettingsScreen> {
  Map<String, dynamic> _settings = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final values = await ref.read(settingsServiceProvider).getSettings();
      if (!mounted) return;
      setState(() => _settings = values);
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
        error,
        context: '${widget.runtimeType}._load',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      AppFeedback.showError(context, mapped);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    if (!mounted) return;
    try {
      await ref.read(settingsServiceProvider).updateSetting(key, value);
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
        error,
        context: '${widget.runtimeType}._update',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      AppFeedback.showError(context, mapped);
      return;
    }
    if (!mounted) return;
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final streakGoal = (_settings['habitsDefaultStreakGoal'] as int?) ?? 21;
    final defaultReminderMinutes = (_settings['habitsDefaultReminderMinutes'] as int?) ?? 480;
    final defaultReminderTime = TimeOfDay(
      hour: defaultReminderMinutes ~/ 60,
      minute: defaultReminderMinutes % 60,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.habits, label: 'Enable habit reminders'),
          ListTile(
            title: const Text('Default reminder time for new habits'),
            subtitle: Text(defaultReminderTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: defaultReminderTime);
              if (picked != null) {
                await _update('habitsDefaultReminderMinutes', picked.hour * 60 + picked.minute);
              }
            },
          ),
          const SettingsSectionHeader('Goals'),
          PickerListTile<int>(
            title: 'Default streak goal',
            value: streakGoal,
            icon: Icons.local_fire_department_outlined,
            options: const [
              PickerOption(7, '7 days'),
              PickerOption(21, '21 days'),
              PickerOption(30, '30 days'),
              PickerOption(66, '66 days'),
              PickerOption(90, '90 days'),
            ],
            onChanged: (value) => _update('habitsDefaultStreakGoal', value),
          ),
        ],
      ),
    );
  }
}
