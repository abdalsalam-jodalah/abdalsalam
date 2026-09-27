import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/settings_section_header.dart';

class SleepSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/sleep';

  const SleepSettingsScreen({super.key});

  @override
  ConsumerState<SleepSettingsScreen> createState() => _SleepSettingsScreenState();
}

class _SleepSettingsScreenState extends ConsumerState<SleepSettingsScreen> {
  static const double _minSleepGoalHours = 4;
  static const double _maxSleepGoalHours = 12;
  static const int _sleepGoalDivisions = 16;

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

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final sleepGoalHours = (_settings['sleepGoalHours'] as num?)?.toDouble() ?? 8.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Reminders'),
          const AppCard(
            padding: EdgeInsets.zero,
            child: ModuleReminderToggleList(module: ReminderModule.sleep, label: 'Enable sleep reminders'),
          ),
          const SettingsSectionHeader('Goals'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Weekly sleep goal'),
                  subtitle: Text('${sleepGoalHours.toStringAsFixed(1)} hours per night'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: Slider(
                    value: sleepGoalHours,
                    min: _minSleepGoalHours,
                    max: _maxSleepGoalHours,
                    divisions: _sleepGoalDivisions,
                    label: '${sleepGoalHours.toStringAsFixed(1)}h',
                    onChanged: (value) => setState(() => _settings['sleepGoalHours'] = value),
                    onChangeEnd: (value) => _update('sleepGoalHours', value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
