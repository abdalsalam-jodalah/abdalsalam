import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class FoodSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/food';

  const FoodSettingsScreen({super.key});

  @override
  ConsumerState<FoodSettingsScreen> createState() => _FoodSettingsScreenState();
}

class _FoodSettingsScreenState extends ConsumerState<FoodSettingsScreen> {
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
    final calorieTarget = (_settings['foodDailyCalorieTarget'] as int?) ?? 2000;
    final proteinTarget = (_settings['foodDailyProteinTargetGrams'] as int?) ?? 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Food')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.food, label: 'Enable food logging reminders'),
          const SettingsSectionHeader('Daily targets'),
          PickerListTile<int>(
            title: 'Daily calorie target',
            value: calorieTarget,
            icon: Icons.local_fire_department_outlined,
            options: const [
              PickerOption(1500, '1500 kcal'),
              PickerOption(1800, '1800 kcal'),
              PickerOption(2000, '2000 kcal'),
              PickerOption(2200, '2200 kcal'),
              PickerOption(2500, '2500 kcal'),
            ],
            onChanged: (value) => _update('foodDailyCalorieTarget', value),
          ),
          PickerListTile<int>(
            title: 'Daily protein target',
            value: proteinTarget,
            icon: Icons.egg_outlined,
            options: const [
              PickerOption(60, '60 g'),
              PickerOption(80, '80 g'),
              PickerOption(100, '100 g'),
              PickerOption(120, '120 g'),
              PickerOption(150, '150 g'),
            ],
            onChanged: (value) => _update('foodDailyProteinTargetGrams', value),
          ),
        ],
      ),
    );
  }
}
