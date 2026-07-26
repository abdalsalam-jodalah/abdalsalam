import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../calendar/screens/google_calendar_sync_screen.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class CalendarSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/calendar';

  const CalendarSettingsScreen({super.key});

  @override
  ConsumerState<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends ConsumerState<CalendarSettingsScreen> {
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
    final googleSyncEnabled = (_settings['calendarGoogleSyncEnabled'] as bool?) ?? false;
    final reminderType = (_settings['calendarReminderType'] as String?) ?? 'notification';

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.calendar, label: 'Enable event reminders'),
          PickerListTile<String>(
            title: 'Reminder type',
            value: reminderType,
            icon: Icons.notifications_outlined,
            options: const [
              PickerOption('notification', 'Push notification'),
              PickerOption('email', 'Email'),
            ],
            onChanged: (value) => _update('calendarReminderType', value),
          ),
          const SettingsSectionHeader('Sync'),
          SwitchListTile(
            value: googleSyncEnabled,
            title: const Text('Google Calendar sync'),
            subtitle: const Text('Calendar sync is not implemented yet — this only stores the preference'),
            onChanged: (value) => _update('calendarGoogleSyncEnabled', value),
          ),
          ListTile(
            title: const Text('Google Calendar sync setup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(GoogleCalendarSyncScreen.routeName),
          ),
        ],
      ),
    );
  }
}
