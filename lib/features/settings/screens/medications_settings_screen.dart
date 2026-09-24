import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../health/screens/medication_list_screen.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class MedicationsSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/medications';

  const MedicationsSettingsScreen({super.key});

  @override
  ConsumerState<MedicationsSettingsScreen> createState() => _MedicationsSettingsScreenState();
}

class _MedicationsSettingsScreenState extends ConsumerState<MedicationsSettingsScreen> {
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
    final refillReminderDays = (_settings['medicationsDefaultRefillReminderDays'] as int?) ?? 7;

    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Refill reminders'),
          PickerListTile<int>(
            title: 'Default refill reminder lead time',
            value: refillReminderDays,
            icon: Icons.medication_outlined,
            options: const [
              PickerOption(3, '3 days before running out'),
              PickerOption(7, '7 days before running out'),
              PickerOption(14, '14 days before running out'),
            ],
            onChanged: (value) => _update('medicationsDefaultRefillReminderDays', value),
          ),
          const SettingsSectionHeader('Manage'),
          ListTile(
            title: const Text('Medications'),
            subtitle: const Text('Reminders and refill dates are set per medication'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(MedicationListScreen.routeName),
          ),
        ],
      ),
    );
  }
}
