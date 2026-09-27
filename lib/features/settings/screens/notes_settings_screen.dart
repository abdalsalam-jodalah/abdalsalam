import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/picker_list_tile.dart';
import '../../notes/screens/note_categories_screen.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/settings_section_header.dart';

class NotesSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/notes';

  const NotesSettingsScreen({super.key});

  @override
  ConsumerState<NotesSettingsScreen> createState() => _NotesSettingsScreenState();
}

class _NotesSettingsScreenState extends ConsumerState<NotesSettingsScreen> {
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
    final defaultColor = (_settings['notesDefaultColor'] as String?) ?? 'default';
    final defaultPinned = (_settings['notesDefaultPinned'] as bool?) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const SettingsSectionHeader('Reminders'),
          const AppCard(
            padding: EdgeInsets.zero,
            child: ModuleReminderToggleList(module: ReminderModule.notes, label: 'Enable note reminders'),
          ),
          const SettingsSectionHeader('Defaults for new notes'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                PickerListTile<String>(
                  title: 'Default note color',
                  value: defaultColor,
                  icon: Icons.palette_outlined,
                  options: const [
                    PickerOption('default', 'Default'),
                    PickerOption('yellow', 'Yellow'),
                    PickerOption('blue', 'Blue'),
                    PickerOption('green', 'Green'),
                    PickerOption('pink', 'Pink'),
                  ],
                  onChanged: (value) => _update('notesDefaultColor', value),
                ),
                SwitchListTile(
                  value: defaultPinned,
                  title: const Text('Pin new notes by default'),
                  onChanged: (value) => _update('notesDefaultPinned', value),
                ),
              ],
            ),
          ),
          const SettingsSectionHeader('Manage'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              title: const Text('Categories'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pushNamed(NoteCategoriesScreen.routeName),
            ),
          ),
        ],
      ),
    );
  }
}
