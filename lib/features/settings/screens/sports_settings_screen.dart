import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class SportsSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/sports';

  const SportsSettingsScreen({super.key});

  @override
  ConsumerState<SportsSettingsScreen> createState() => _SportsSettingsScreenState();
}

class _SportsSettingsScreenState extends ConsumerState<SportsSettingsScreen> {
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
    final unitSystem = (_settings['sportsUnitSystem'] as String?) ?? 'metric';
    final weeklyGoal = (_settings['sportsWeeklyWorkoutGoal'] as int?) ?? 3;
    final dailySteps = (_settings['sportsDailyStepGoal'] as int?) ?? 8000;

    return Scaffold(
      appBar: AppBar(title: const Text('Sports')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.sports, label: 'Enable workout reminders'),
          const SettingsSectionHeader('Units & goals'),
          PickerListTile<String>(
            title: 'Unit system',
            value: unitSystem,
            icon: Icons.straighten_outlined,
            options: const [
              PickerOption('metric', 'Metric (kg, km)'),
              PickerOption('imperial', 'Imperial (lb, mi)'),
            ],
            onChanged: (value) => _update('sportsUnitSystem', value),
          ),
          PickerListTile<int>(
            title: 'Weekly workout goal',
            value: weeklyGoal,
            icon: Icons.fitness_center,
            options: const [
              PickerOption(2, '2 per week'),
              PickerOption(3, '3 per week'),
              PickerOption(4, '4 per week'),
              PickerOption(5, '5 per week'),
              PickerOption(7, '7 per week'),
            ],
            onChanged: (value) => _update('sportsWeeklyWorkoutGoal', value),
          ),
          PickerListTile<int>(
            title: 'Daily step goal',
            value: dailySteps,
            icon: Icons.directions_walk,
            options: const [
              PickerOption(5000, '5,000 steps'),
              PickerOption(8000, '8,000 steps'),
              PickerOption(10000, '10,000 steps'),
              PickerOption(12000, '12,000 steps'),
            ],
            onChanged: (value) => _update('sportsDailyStepGoal', value),
          ),
        ],
      ),
    );
  }
}
