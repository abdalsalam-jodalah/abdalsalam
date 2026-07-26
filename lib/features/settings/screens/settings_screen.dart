import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/religious/providers/religious_tracking_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart' as reminders;
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
  Map<String, bool> _moduleNotifications = const {};
  String _pendingPrayerSource = 'scraped';
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await ref.read(settingsServiceProvider).getSettings();
    final moduleSettings = await ref.read(reminderServiceProvider).getModuleSettings();
    if (mounted) {
      setState(() {
        _settings = values;
        _moduleNotifications = moduleSettings;
        _pendingPrayerSource = (values['prayerTimeSource'] as String?) ?? 'scraped';
        _latController.text = ((values['prayerLocationLatitude'] as num?) ?? 32.2211).toString();
        _longController.text = ((values['prayerLocationLongitude'] as num?) ?? 35.2544).toString();
      });
    }
  }

  Future<void> _confirmPrayerSource() async {
    await _update('prayerTimeSource', _pendingPrayerSource);
    if (_pendingPrayerSource == 'adhan') {
      await _update('prayerLocationLatitude', double.tryParse(_latController.text) ?? 32.2211);
      await _update('prayerLocationLongitude', double.tryParse(_longController.text) ?? 35.2544);
    }
    await ref.read(religiousTrackerServiceProvider).syncPrayerTimesForToday(force: true);
    ref.invalidate(todayPrayerTimesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer time source updated')),
      );
    }
  }

  Future<void> _update(String key, dynamic value) async {
    await ref.read(settingsServiceProvider).updateSetting(key, value);
    setState(() => _settings[key] = value);
  }

  Future<void> _updateModuleNotification(String module, bool enabled) async {
    final reminderModule = reminders.ReminderModule.values.byName(module);
    await ref.read(reminderServiceProvider).setModuleEnabled(reminderModule, enabled);
    setState(() => _moduleNotifications[module] = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = (_settings['themeMode'] as String?) ?? 'system';
    final notificationsEnabled = (_settings['notificationsEnabled'] as bool?) ?? true;
    final autoBackup = (_settings['autoBackupEnabled'] as bool?) ?? false;
    final biometric = (_settings['biometricEnabled'] as bool?) ?? true;
    final language = (_settings['language'] as String?) ?? 'en';
    final firstDay = (_settings['firstDayOfWeek'] as String?) ?? 'saturday';
    final prayerMethod = (_settings['prayerMethod'] as String?) ?? 'muslim_world_league';
    final religiousRemindersEnabled = (_settings['religiousRemindersEnabled'] as bool?) ?? true;
    final religiousPrayerRemindersEnabled = (_settings['religiousPrayerRemindersEnabled'] as bool?) ?? true;
    final religiousQuranRemindersEnabled = (_settings['religiousQuranRemindersEnabled'] as bool?) ?? true;
    final religiousAthkarRemindersEnabled = (_settings['religiousAthkarRemindersEnabled'] as bool?) ?? true;
    final religiousNightRemindersEnabled = (_settings['religiousNightRemindersEnabled'] as bool?) ?? true;
    final religiousBadEventRemindersEnabled = (_settings['religiousBadEventRemindersEnabled'] as bool?) ?? true;
    final religiousDefaultReminderMinutes = (_settings['religiousDefaultReminderMinutes'] as int?) ?? 10;
    final religiousPrayerTimesRetentionDays =
      (_settings['religiousPrayerTimesRetentionDays'] as int?) ?? 365;
    final autoLockMinutes = (_settings['autoLockMinutes'] as int?) ?? 5;
    final backupReminderDays = (_settings['backupReminderDays'] as int?) ?? 7;
    final notificationPriority = (_settings['notificationPriority'] as String?) ?? 'default';
    final sleepGoalHours = (_settings['sleepGoalHours'] as num?)?.toDouble() ?? 8.0;
    final dashboardHidden = (_settings['dashboardHiddenCards'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toSet();

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
          const ListTile(title: Text('Localization')),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(language == 'ar' ? 'Arabic' : 'English'),
            trailing: const Icon(Icons.translate),
            onTap: () => _update('language', language == 'en' ? 'ar' : 'en'),
          ),
          ListTile(
            title: const Text('First day of week'),
            subtitle: Text(firstDay),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _update('firstDayOfWeek', firstDay == 'saturday' ? 'monday' : 'saturday'),
          ),
          const Divider(),
          const ListTile(title: Text('Notifications')),
          SwitchListTile(
            value: notificationsEnabled,
            title: const Text('Enable notifications'),
            onChanged: (value) => _update('notificationsEnabled', value),
          ),
          for (final module in reminders.ReminderModule.values)
            SwitchListTile(
              value: _moduleNotifications[module.name] ?? true,
              title: Text('Enable ${module.name} reminders'),
              dense: true,
              onChanged: notificationsEnabled
                  ? (value) => _updateModuleNotification(module.name, value)
                  : null,
            ),
          ListTile(
            title: const Text('Notification sound'),
            subtitle: Text((_settings['notificationSound'] as String?) ?? 'default'),
            trailing: const Icon(Icons.music_note_outlined),
            onTap: () => _update('notificationSound', 'default'),
          ),
          ListTile(
            title: const Text('Notification priority'),
            subtitle: Text(notificationPriority),
            trailing: const Icon(Icons.priority_high_outlined),
            onTap: () => _update('notificationPriority', notificationPriority == 'high' ? 'default' : 'high'),
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
          ListTile(
            title: const Text('Prayer calculation method'),
            subtitle: Text(prayerMethod),
            trailing: const Icon(Icons.calculate_outlined),
            onTap: () => _update(
              'prayerMethod',
              prayerMethod == 'muslim_world_league' ? 'umm_al_qura' : 'muslim_world_league',
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Prayer Times Source')),
          RadioListTile<String>(
            value: 'scraped',
            groupValue: _pendingPrayerSource,
            title: const Text('Local source (quran-radio.com)'),
            subtitle: const Text('Default — localized to your country'),
            onChanged: (value) {
              if (value != null) {
                setState(() => _pendingPrayerSource = value);
              }
            },
          ),
          RadioListTile<String>(
            value: 'adhan',
            groupValue: _pendingPrayerSource,
            title: const Text('Calculated (Adhan, Muslim World League)'),
            subtitle: const Text('Computed locally from latitude/longitude'),
            onChanged: (value) {
              if (value != null) {
                setState(() => _pendingPrayerSource = value);
              }
            },
          ),
          if (_pendingPrayerSource == 'adhan')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _longController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer(
              builder: (context, ref, _) {
                final preview = ref.watch(prayerTimeSourcePreviewProvider(_pendingPrayerSource));
                return preview.when(
                  data: (times) => Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final entry in times.entries)
                        Chip(label: Text('${entry.key}: ${DateFormat('hh:mm a').format(entry.value)}')),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (err, _) => Text('Preview unavailable: $err'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FilledButton(
              onPressed: _confirmPrayerSource,
              child: const Text('Use this source'),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Religious Reminders')),
          SwitchListTile(
            value: religiousRemindersEnabled,
            title: const Text('Enable religious reminders'),
            onChanged: (value) => _update('religiousRemindersEnabled', value),
          ),
          SwitchListTile(
            value: religiousPrayerRemindersEnabled,
            title: const Text('Prayer reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _update('religiousPrayerRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousQuranRemindersEnabled,
            title: const Text('Quran reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _update('religiousQuranRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousAthkarRemindersEnabled,
            title: const Text('Athkar reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _update('religiousAthkarRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousNightRemindersEnabled,
            title: const Text('Night prayer reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _update('religiousNightRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousBadEventRemindersEnabled,
            title: const Text('Bad event reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _update('religiousBadEventRemindersEnabled', value)
                : null,
          ),
          ListTile(
            title: const Text('Prayer reminder lead time'),
            subtitle: Text('$religiousDefaultReminderMinutes minutes before prayer'),
            trailing: const Icon(Icons.schedule_outlined),
            onTap: () => _update(
              'religiousDefaultReminderMinutes',
              religiousDefaultReminderMinutes == 10 ? 15 : 10,
            ),
          ),
          ListTile(
            title: const Text('Prayer times history retention'),
            subtitle: Text('$religiousPrayerTimesRetentionDays days (minimum 365)'),
            trailing: const Icon(Icons.storage_outlined),
            onTap: () => _update(
              'religiousPrayerTimesRetentionDays',
              religiousPrayerTimesRetentionDays == 365 ? 730 : 365,
            ),
          ),
          ListTile(
            title: const Text('Vault auto-lock timeout'),
            subtitle: Text('$autoLockMinutes minutes'),
            trailing: const Icon(Icons.timer_outlined),
            onTap: () => _update('autoLockMinutes', autoLockMinutes == 5 ? 10 : 5),
          ),
          const Divider(),
          const ListTile(title: Text('Sleep')),
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
          const Divider(),
          const ListTile(title: Text('Backup & Restore')),
          SwitchListTile(
            value: autoBackup,
            title: const Text('Automatic backup'),
            onChanged: (value) => _update('autoBackupEnabled', value),
          ),
          ListTile(
            title: const Text('Backup reminder frequency'),
            subtitle: Text('Every $backupReminderDays days'),
            trailing: const Icon(Icons.notifications_active_outlined),
            onTap: () => _update('backupReminderDays', backupReminderDays == 7 ? 3 : 7),
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
          const ListTile(title: Text('Dashboard Customization')),
          for (final moduleId in const [
            'religious',
            'financial',
            'habits',
            'sports',
            'health',
            'notes',
            'calendar',
            'security',
            'analytics',
          ])
            CheckboxListTile(
              title: Text('Show $moduleId card'),
              value: !dashboardHidden.contains(moduleId),
              onChanged: (value) {
                final next = {...dashboardHidden};
                if (value == true) {
                  next.remove(moduleId);
                } else {
                  next.add(moduleId);
                }
                _update('dashboardHiddenCards', next.toList(growable: false));
              },
            ),
          ListTile(
            title: const Text('Rotate card order'),
            subtitle: const Text('Quickly cycle dashboard card order'),
            trailing: const Icon(Icons.swap_vert),
            onTap: () {
              final order = (_settings['dashboardCardOrder'] as List<dynamic>? ?? const <dynamic>[])
                  .map((item) => item.toString())
                  .toList(growable: true);
              if (order.length > 1) {
                final first = order.removeAt(0);
                order.add(first);
                _update('dashboardCardOrder', order);
              }
            },
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
