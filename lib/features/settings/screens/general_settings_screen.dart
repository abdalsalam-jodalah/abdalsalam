import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';
import 'backup_screen.dart';
import 'restore_screen.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/general';

  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
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

  Future<void> _resetToDefaults() async {
    try {
      await ref.read(settingsServiceProvider).resetToDefaults();
    } catch (error, stackTrace) {
      final mapped = ref.read(errorHandlerProvider).mapException(
        error,
        context: '${widget.runtimeType}._resetToDefaults',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      AppFeedback.showError(context, mapped);
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = (_settings['themeMode'] as String?) ?? 'system';
    final language = (_settings['language'] as String?) ?? 'en';
    final firstDay = (_settings['firstDayOfWeek'] as String?) ?? 'saturday';
    final notificationsEnabled = (_settings['notificationsEnabled'] as bool?) ?? true;
    final notificationSound = (_settings['notificationSound'] as String?) ?? 'default';
    final notificationPriority = (_settings['notificationPriority'] as String?) ?? 'default';
    final respectDoNotDisturb = (_settings['respectDoNotDisturb'] as bool?) ?? true;
    final autoBackup = (_settings['autoBackupEnabled'] as bool?) ?? false;
    final backupReminderDays = (_settings['backupReminderDays'] as int?) ?? 7;

    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Appearance'),
          PickerListTile<String>(
            title: 'Theme mode',
            value: themeMode,
            icon: Icons.brightness_6_outlined,
            options: const [
              PickerOption('system', 'System theme'),
              PickerOption('light', 'Light theme'),
              PickerOption('dark', 'Dark theme'),
            ],
            onChanged: (value) => _update('themeMode', value),
          ),
          const SettingsSectionHeader('Localization'),
          PickerListTile<String>(
            title: 'Language',
            value: language,
            icon: Icons.translate,
            options: const [
              PickerOption('en', 'English'),
              PickerOption('ar', 'Arabic'),
            ],
            onChanged: (value) => _update('language', value),
          ),
          PickerListTile<String>(
            title: 'First day of week',
            value: firstDay,
            icon: Icons.calendar_today_outlined,
            options: const [
              PickerOption('saturday', 'Saturday'),
              PickerOption('sunday', 'Sunday'),
              PickerOption('monday', 'Monday'),
            ],
            onChanged: (value) => _update('firstDayOfWeek', value),
          ),
          const SettingsSectionHeader('Notifications'),
          SwitchListTile(
            value: notificationsEnabled,
            title: const Text('Enable notifications'),
            onChanged: (value) => _update('notificationsEnabled', value),
          ),
          PickerListTile<String>(
            title: 'Notification sound',
            value: notificationSound,
            icon: Icons.music_note_outlined,
            options: const [
              PickerOption('default', 'Default'),
              PickerOption('none', 'Silent'),
            ],
            onChanged: (value) => _update('notificationSound', value),
          ),
          PickerListTile<String>(
            title: 'Notification priority',
            value: notificationPriority,
            icon: Icons.priority_high_outlined,
            options: const [
              PickerOption('default', 'Default'),
              PickerOption('high', 'High'),
            ],
            onChanged: (value) => _update('notificationPriority', value),
          ),
          SwitchListTile(
            value: respectDoNotDisturb,
            title: const Text('Respect Do Not Disturb'),
            subtitle: const Text('Deliver reminders at a low-interruption level'),
            onChanged: (value) => _update('respectDoNotDisturb', value),
          ),
          const SettingsSectionHeader('Backup & Restore'),
          SwitchListTile(
            value: autoBackup,
            title: const Text('Automatic backup'),
            onChanged: (value) => _update('autoBackupEnabled', value),
          ),
          PickerListTile<int>(
            title: 'Backup reminder frequency',
            value: backupReminderDays,
            icon: Icons.notifications_active_outlined,
            options: const [
              PickerOption(1, 'Every day'),
              PickerOption(3, 'Every 3 days'),
              PickerOption(7, 'Every 7 days'),
              PickerOption(14, 'Every 14 days'),
              PickerOption(30, 'Every 30 days'),
            ],
            onChanged: (value) => _update('backupReminderDays', value),
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
            onTap: _resetToDefaults,
          ),
        ],
      ),
    );
  }
}
