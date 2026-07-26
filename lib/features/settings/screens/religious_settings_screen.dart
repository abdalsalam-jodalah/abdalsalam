import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/religious/providers/religious_tracking_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
import '../widgets/settings_section_header.dart';

class ReligiousSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/religious';

  const ReligiousSettingsScreen({super.key});

  @override
  ConsumerState<ReligiousSettingsScreen> createState() => _ReligiousSettingsScreenState();
}

class _ReligiousSettingsScreenState extends ConsumerState<ReligiousSettingsScreen> {
  Map<String, dynamic> _settings = const {};
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
    if (mounted) {
      setState(() {
        _settings = values;
        _pendingPrayerSource = (values['prayerTimeSource'] as String?) ?? 'scraped';
        _latController.text = ((values['prayerLocationLatitude'] as num?) ?? 32.2211).toString();
        _longController.text = ((values['prayerLocationLongitude'] as num?) ?? 35.2544).toString();
      });
    }
  }

  Future<void> _update(String key, dynamic value) async {
    await ref.read(settingsServiceProvider).updateSetting(key, value);
    setState(() => _settings[key] = value);
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

  @override
  Widget build(BuildContext context) {
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
    final quranDailyGoalPages = (_settings['religiousQuranDailyGoalPages'] as int?) ?? 1;
    final badEventThreshold = (_settings['religiousBadEventThreshold'] as int?) ?? 3;

    return Scaffold(
      appBar: AppBar(title: const Text('Religious')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Prayer calculation'),
          PickerListTile<String>(
            title: 'Prayer calculation method',
            value: prayerMethod,
            icon: Icons.calculate_outlined,
            options: const [
              PickerOption('muslim_world_league', 'Muslim World League'),
              PickerOption('egyptian', 'Egyptian General Authority'),
              PickerOption('karachi', 'University of Islamic Sciences, Karachi'),
              PickerOption('umm_al_qura', 'Umm al-Qura, Makkah'),
              PickerOption('dubai', 'Dubai'),
              PickerOption('moon_sighting_committee', 'Moon Sighting Committee'),
              PickerOption('north_america', 'ISNA (North America)'),
              PickerOption('kuwait', 'Kuwait'),
              PickerOption('qatar', 'Qatar'),
              PickerOption('singapore', 'Singapore'),
            ],
            onChanged: (value) => _update('prayerMethod', value),
          ),
          const SettingsSectionHeader('Prayer Times Source'),
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
            title: const Text('Calculated (Adhan)'),
            subtitle: const Text('Computed locally from latitude/longitude and your chosen method'),
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
          const SettingsSectionHeader('Reminders'),
          ModuleReminderToggleList(module: ReminderModule.religious, label: 'Enable religious reminders'),
          SwitchListTile(
            value: religiousRemindersEnabled,
            title: const Text('Detailed reminder types'),
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
          PickerListTile<int>(
            title: 'Prayer reminder lead time',
            value: religiousDefaultReminderMinutes,
            icon: Icons.schedule_outlined,
            options: const [
              PickerOption(5, '5 minutes before'),
              PickerOption(10, '10 minutes before'),
              PickerOption(15, '15 minutes before'),
              PickerOption(20, '20 minutes before'),
              PickerOption(30, '30 minutes before'),
            ],
            onChanged: (value) => _update('religiousDefaultReminderMinutes', value),
          ),
          const SettingsSectionHeader('Data & goals'),
          PickerListTile<int>(
            title: 'Prayer times history retention',
            value: religiousPrayerTimesRetentionDays,
            icon: Icons.storage_outlined,
            options: const [
              PickerOption(365, '365 days'),
              PickerOption(730, '730 days'),
              PickerOption(1095, '1095 days'),
            ],
            onChanged: (value) => _update('religiousPrayerTimesRetentionDays', value),
          ),
          PickerListTile<int>(
            title: 'Quran daily reading goal',
            value: quranDailyGoalPages,
            icon: Icons.menu_book_outlined,
            options: const [
              PickerOption(1, '1 page a day'),
              PickerOption(3, '3 pages a day'),
              PickerOption(5, '5 pages a day'),
              PickerOption(10, '10 pages a day'),
            ],
            onChanged: (value) => _update('religiousQuranDailyGoalPages', value),
          ),
          PickerListTile<int>(
            title: 'Bad-event streak alert threshold',
            value: badEventThreshold,
            icon: Icons.warning_amber_outlined,
            options: const [
              PickerOption(1, 'After 1 occurrence'),
              PickerOption(3, 'After 3 occurrences'),
              PickerOption(5, 'After 5 occurrences'),
            ],
            onChanged: (value) => _update('religiousBadEventThreshold', value),
          ),
        ],
      ),
    );
  }
}
