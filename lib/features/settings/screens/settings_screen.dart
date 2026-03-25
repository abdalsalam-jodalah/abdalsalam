import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import 'backup_screen.dart';
import 'restore_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final themeMode = (_settings['themeMode'] as String?) ?? 'system';
    final notificationsEnabled = (_settings['notificationsEnabled'] as bool?) ?? true;
    final autoBackup = (_settings['autoBackupEnabled'] as bool?) ?? false;
    final biometric = (_settings['biometricEnabled'] as bool?) ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Appearance')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: themeMode,
              decoration: const InputDecoration(labelText: 'Theme mode'),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('System theme')),
                DropdownMenuItem(value: 'light', child: Text('Light theme')),
                DropdownMenuItem(value: 'dark', child: Text('Dark theme')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _update('themeMode', value);
                }
              },
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Notifications')),
          SwitchListTile(
            value: notificationsEnabled,
            title: const Text('Enable notifications'),
            onChanged: (value) => _update('notificationsEnabled', value),
          ),
          const Divider(),
          const ListTile(title: Text('Module Settings')),
          SwitchListTile(
            value: biometric,
            title: const Text('Enable biometric vault lock'),
            onChanged: (value) => _update('biometricEnabled', value),
          ),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text((_settings['currency'] as String?) ?? 'USD'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _update('currency', 'USD'),
          ),
          const Divider(),
          const ListTile(title: Text('Backup & Restore')),
          SwitchListTile(
            value: autoBackup,
            title: const Text('Automatic backup'),
            onChanged: (value) => _update('autoBackupEnabled', value),
          ),
          ListTile(
            title: const Text('Backup now'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(BackupScreen.routeName),
          ),
          ListTile(
            title: const Text('Restore backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(RestoreScreen.routeName),
          ),
          const Divider(),
          ListTile(
            title: const Text('Reset to defaults'),
            onTap: () async {
              await ref.read(settingsServiceProvider).resetToDefaults();
              await _load();
            },
          ),
        ],
      ),
    );
  }
}
