import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/auto_backup_service.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/picker_list_tile.dart';

class AutoBackupSettingsCard extends ConsumerStatefulWidget {
  const AutoBackupSettingsCard({super.key});

  @override
  ConsumerState<AutoBackupSettingsCard> createState() => _AutoBackupSettingsCardState();
}

class _AutoBackupSettingsCardState extends ConsumerState<AutoBackupSettingsCard> {
  static const String _neverLabel = 'Never';
  static const String _dateTimePattern = 'MMM d, y  h:mm a';

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
      _report(error, stackTrace, '_load');
    }
  }

  Future<void> _update(String key, dynamic value) async {
    try {
      await ref.read(settingsServiceProvider).updateSetting(key, value);
    } catch (error, stackTrace) {
      _report(error, stackTrace, '_update');
      return;
    }
    if (!mounted) return;
    setState(() => _settings = {..._settings, key: value});
    ref.invalidate(backupReminderDaysProvider);
    if (key == AutoBackupService.enabledSettingKey && value == true) {
      await ref.read(autoBackupServiceProvider).runIfDue();
      ref.invalidate(backupStatusProvider);
    }
  }

  void _report(Object error, StackTrace stackTrace, String operation) {
    final mapped = ref.read(errorHandlerProvider).mapException(
          error,
          context: '${widget.runtimeType}.$operation',
          stackTrace: stackTrace,
        );
    if (!mounted) return;
    AppFeedback.showError(context, mapped);
  }

  String _describe(DateTime? moment) {
    return moment == null ? _neverLabel : DateFormat(_dateTimePattern).format(moment);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = (_settings[AutoBackupService.enabledSettingKey] as bool?) ?? false;
    final intervalDays = (_settings[AutoBackupService.intervalDaysSettingKey] as int?) ?? AutoBackupService.defaultIntervalDays;
    final status = ref.watch(backupStatusProvider).valueOrNull;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            value: isEnabled,
            title: const Text('Automatic backup'),
            subtitle: const Text('Keeps the latest copies on this device. Still save one outside the phone.'),
            onChanged: (value) => _update(AutoBackupService.enabledSettingKey, value),
          ),
          PickerListTile<int>(
            title: 'Backup frequency and reminder',
            value: intervalDays,
            icon: Icons.notifications_active_outlined,
            options: const [
              PickerOption(1, 'Every day'),
              PickerOption(3, 'Every 3 days'),
              PickerOption(7, 'Every 7 days'),
              PickerOption(14, 'Every 14 days'),
              PickerOption(30, 'Every 30 days'),
            ],
            onChanged: (value) => _update(AutoBackupService.intervalDaysSettingKey, value),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_done_outlined),
            title: const Text('Last saved outside the app'),
            subtitle: Text(_describe(status?.lastExportedAt)),
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Last automatic backup'),
            subtitle: Text(_describe(status?.lastAutoBackupAt)),
          ),
        ],
      ),
    );
  }
}
