import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../notes/screens/note_categories_screen.dart';
import '../widgets/module_reminder_toggle_list.dart';
import '../widgets/picker_list_tile.dart';
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
    final defaultColor = (_settings['notesDefaultColor'] as String?) ?? 'default';
    final defaultPinned = (_settings['notesDefaultPinned'] as bool?) ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        children: [
          const SettingsSectionHeader('Reminders'),
          const ModuleReminderToggleList(module: ReminderModule.notes, label: 'Enable note reminders'),
          const SettingsSectionHeader('Defaults for new notes'),
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
          const SettingsSectionHeader('Manage'),
          ListTile(
            title: const Text('Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(NoteCategoriesScreen.routeName),
          ),
        ],
      ),
    );
  }
}
