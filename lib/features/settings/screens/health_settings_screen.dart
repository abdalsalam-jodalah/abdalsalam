import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class HealthSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/health';

  const HealthSettingsScreen({super.key});

  @override
  ConsumerState<HealthSettingsScreen> createState() => _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends ConsumerState<HealthSettingsScreen> {
  Map<String, dynamic> _settings = const {};

  @override
  void initState() {
    super.initState();
    _load();
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
    final recheckInterval = (_settings['healthBloodTestRecheckIntervalDays'] as int?) ?? 180;
    final unitSystem = (_settings['healthMetricUnitSystem'] as String?) ?? 'metric';

    return Scaffold(
      appBar: AppBar(title: const Text('Health')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.health, label: 'Enable health reminders'),
          const SettingsSectionHeader('Blood tests'),
          PickerListTile<int>(
            title: 'Blood test recheck interval',
            value: recheckInterval,
            icon: Icons.bloodtype_outlined,
            options: const [
              PickerOption(90, 'Every 3 months'),
              PickerOption(180, 'Every 6 months'),
              PickerOption(365, 'Every year'),
            ],
            onChanged: (value) => _update('healthBloodTestRecheckIntervalDays', value),
          ),
          const SettingsSectionHeader('Units'),
          PickerListTile<String>(
            title: 'Health metric units',
            value: unitSystem,
            icon: Icons.straighten_outlined,
            options: const [
              PickerOption('metric', 'Metric (kg, cm)'),
              PickerOption('imperial', 'Imperial (lb, ft)'),
            ],
            onChanged: (value) => _update('healthMetricUnitSystem', value),
          ),
        ],
      ),
    );
  }
}
