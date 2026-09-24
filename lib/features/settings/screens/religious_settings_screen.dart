import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../features/religious/providers/religious_tracking_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
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
  static const double _defaultLatitude = 32.2211;
  static const double _defaultLongitude = 35.2544;
  static const String _prayerTimeSourceUpdatedMessage = 'Prayer time source updated';

  final _locationFormKey = GlobalKey<FormState>();
  Map<String, dynamic> _settings = const {};
  String _pendingPrayerSource = 'scraped';
  final _latController = TextEditingController();
  final _longController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await ref.read(settingsServiceProvider).getSettings();
      if (!mounted) return;
      setState(() {
        _settings = values;
        _pendingPrayerSource = (values['prayerTimeSource'] as String?) ?? 'scraped';
        _latController.text = ((values['prayerLocationLatitude'] as num?) ?? _defaultLatitude).toString();
        _longController.text = ((values['prayerLocationLongitude'] as num?) ?? _defaultLongitude).toString();
      });
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

  Future<AppError?> _update(String key, dynamic value) async {
    try {
      await ref.read(settingsServiceProvider).updateSetting(key, value);
    } catch (error, stackTrace) {
      return ref.read(errorHandlerProvider).mapException(
            error,
            context: 'ReligiousSettingsScreen._update($key)',
            stackTrace: stackTrace,
          );
    }
    if (mounted) {
      setState(() => _settings[key] = value);
    }
    return null;
  }

  Future<void> _updateAndReport(String key, dynamic value) async {
    final error = await _update(key, value);
    if (error != null && mounted) {
      AppFeedback.showError(context, error);
    }
  }

  String? _validateLatitude(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Latitude');
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Latitude must be a number';
    return ValidationUtils.numericRange(value: parsed, fieldName: 'Latitude', min: -90, max: 90);
  }

  String? _validateLongitude(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Longitude');
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Longitude must be a number';
    return ValidationUtils.numericRange(value: parsed, fieldName: 'Longitude', min: -180, max: 180);
  }

  Future<void> _confirmPrayerSource() async {
    final usingAdhan = _pendingPrayerSource == 'adhan';
    if (usingAdhan && !(_locationFormKey.currentState?.validate() ?? true)) {
      return;
    }

    final sourceError = await _update('prayerTimeSource', _pendingPrayerSource);
    if (sourceError != null) {
      if (mounted) AppFeedback.showError(context, sourceError);
      return;
    }

    if (usingAdhan) {
      final latitudeError = await _update(
        'prayerLocationLatitude',
        double.parse(_latController.text.trim()),
      );
      if (latitudeError != null) {
        if (mounted) AppFeedback.showError(context, latitudeError);
        return;
      }
      final longitudeError = await _update(
        'prayerLocationLongitude',
        double.parse(_longController.text.trim()),
      );
      if (longitudeError != null) {
        if (mounted) AppFeedback.showError(context, longitudeError);
        return;
      }
    }

    final syncResult =
        await ref.read(religiousTrackerServiceProvider).syncPrayerTimesForToday(force: true);
    if (!mounted) return;
    if (syncResult.isFailure) {
      AppFeedback.showError(context, syncResult.error!);
      return;
    }
    ref.invalidate(todayPrayerTimesProvider);
    AppFeedback.showSuccess(context, _prayerTimeSourceUpdatedMessage);
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
            onChanged: (value) => _updateAndReport('prayerMethod', value),
          ),
          const SettingsSectionHeader('Prayer Times Source'),
          RadioGroup<String>(
            groupValue: _pendingPrayerSource,
            onChanged: (value) {
              if (value != null) {
                setState(() => _pendingPrayerSource = value);
              }
            },
            child: const Column(
              children: [
                RadioListTile<String>(
                  value: 'scraped',
                  title: Text('Local source (quran-radio.com)'),
                  subtitle: Text('Default — localized to your country'),
                ),
                RadioListTile<String>(
                  value: 'adhan',
                  title: Text('Calculated (Adhan)'),
                  subtitle: Text('Computed locally from latitude/longitude and your chosen method'),
                ),
              ],
            ),
          ),
          if (_pendingPrayerSource == 'adhan')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _locationFormKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        validator: _validateLatitude,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        validator: _validateLongitude,
                      ),
                    ),
                  ],
                ),
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
                  error: (err, _) => AsyncErrorView(
                    error: err,
                    isCompact: true,
                    onRetry: () => ref.invalidate(prayerTimeSourcePreviewProvider(_pendingPrayerSource)),
                  ),
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
            onChanged: (value) => _updateAndReport('religiousRemindersEnabled', value),
          ),
          SwitchListTile(
            value: religiousPrayerRemindersEnabled,
            title: const Text('Prayer reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _updateAndReport('religiousPrayerRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousQuranRemindersEnabled,
            title: const Text('Quran reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _updateAndReport('religiousQuranRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousAthkarRemindersEnabled,
            title: const Text('Athkar reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _updateAndReport('religiousAthkarRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousNightRemindersEnabled,
            title: const Text('Night prayer reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _updateAndReport('religiousNightRemindersEnabled', value)
                : null,
          ),
          SwitchListTile(
            value: religiousBadEventRemindersEnabled,
            title: const Text('Bad event reminders'),
            dense: true,
            onChanged: religiousRemindersEnabled
                ? (value) => _updateAndReport('religiousBadEventRemindersEnabled', value)
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
            onChanged: (value) => _updateAndReport('religiousDefaultReminderMinutes', value),
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
            onChanged: (value) => _updateAndReport('religiousPrayerTimesRetentionDays', value),
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
            onChanged: (value) => _updateAndReport('religiousQuranDailyGoalPages', value),
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
            onChanged: (value) => _updateAndReport('religiousBadEventThreshold', value),
          ),
        ],
      ),
    );
  }
}
