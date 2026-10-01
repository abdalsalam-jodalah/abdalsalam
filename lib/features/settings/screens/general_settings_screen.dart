import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';
import 'data_management_screen.dart';

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
    final language = (_settings['language'] as String?) ?? 'en';
    final firstDay = (_settings['firstDayOfWeek'] as String?) ?? 'saturday';
    final notificationsEnabled = (_settings['notificationsEnabled'] as bool?) ?? true;
    final notificationSound = (_settings['notificationSound'] as String?) ?? 'default';
    final notificationPriority = (_settings['notificationPriority'] as String?) ?? 'default';
    final respectDoNotDisturb = (_settings['respectDoNotDisturb'] as bool?) ?? true;

    final spacing = AppThemeTokens.of(context).spacing;

    return Scaffold(
      appBar: AppBar(title: const Text('General')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Localization'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SettingsSectionHeader('Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SettingsSectionHeader('Data'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Data & Backup'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pushNamed(DataManagementScreen.routeName),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: const Text('Reset to defaults'),
              onTap: _resetToDefaults,
            ),
          ),
        ],
      ),
    );
  }
}
