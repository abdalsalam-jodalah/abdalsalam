import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/security';

  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
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
    final biometric = (_settings['biometricEnabled'] as bool?) ?? true;
    final autoLockMinutes = (_settings['autoLockMinutes'] as int?) ?? 5;
    final passwordExpiryDays = (_settings['securityPasswordExpiryDays'] as int?) ?? 90;

    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Vault lock'),
          SwitchListTile(
            value: biometric,
            title: const Text('Enable biometric vault lock'),
            subtitle: const Text('Biometric unlock is not implemented yet — this only stores the preference'),
            onChanged: (value) => _update('biometricEnabled', value),
          ),
          PickerListTile<int>(
            title: 'Vault auto-lock timeout',
            value: autoLockMinutes,
            icon: Icons.timer_outlined,
            options: const [
              PickerOption(1, '1 minute'),
              PickerOption(5, '5 minutes'),
              PickerOption(10, '10 minutes'),
              PickerOption(15, '15 minutes'),
              PickerOption(30, '30 minutes'),
            ],
            onChanged: (value) => _update('autoLockMinutes', value),
          ),
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.security, label: 'Enable security reminders'),
          const SettingsSectionHeader('Password policy'),
          PickerListTile<int>(
            title: 'Password expiry reminder',
            value: passwordExpiryDays,
            icon: Icons.password_outlined,
            options: const [
              PickerOption(30, 'Every 30 days'),
              PickerOption(60, 'Every 60 days'),
              PickerOption(90, 'Every 90 days'),
              PickerOption(180, 'Every 180 days'),
            ],
            onChanged: (value) => _update('securityPasswordExpiryDays', value),
          ),
        ],
      ),
    );
  }
}
