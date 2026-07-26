import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/settings_section_header.dart';

class SleepSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/sleep';

  const SleepSettingsScreen({super.key});

  @override
  ConsumerState<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends ConsumerState<SleepSettingsScreen> {
  Map<String, dynamic> _settings = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await ref.read(settingsServiceProvider).getSettings();
    if (mounted) {
      setState(() => _settings = values);
    }
  }

  Future<void> _update(String key, dynamic value) async {
    await ref.read(settingsServiceProvider).updateSetting(key, value);
    setState(() => _settings[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final sleepGoalHours = (_settings['sleepGoalHours'] as num?)?.toDouble() ?? 8.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.sleep, label: 'Enable sleep reminders'),
          const SettingsSectionHeader('Goals'),
          ListTile(
            title: const Text('Weekly sleep goal'),
            subtitle: Text('${sleepGoalHours.toStringAsFixed(1)} hours per night'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: sleepGoalHours,
              min: 4,
              max: 12,
              divisions: 16,
              label: '${sleepGoalHours.toStringAsFixed(1)}h',
              onChanged: (value) => setState(() => _settings['sleepGoalHours'] = value),
              onChangeEnd: (value) => _update('sleepGoalHours', value),
            ),
          ),
        ],
      ),
    );
  }
}
