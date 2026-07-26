import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';

class ModuleReminderToggleList extends ConsumerStatefulWidget {
  final ReminderModule module;
  final String label;

  const ModuleReminderToggleList({
    super.key,
    required this.module,
    required this.label,
  });

  @override
  ConsumerState<ModuleReminderToggleList> createState() => _ModuleReminderToggleListState();
}

class _ModuleReminderToggleListState extends ConsumerState<ModuleReminderToggleList> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ref.read(reminderServiceProvider).getModuleSettings();
    if (mounted) {
      setState(() => _enabled = settings[widget.module.name] ?? true);
    }
  }

  Future<void> _update(bool value) async {
    await ref.read(reminderServiceProvider).setModuleEnabled(widget.module, value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null) {
      return const SizedBox.shrink();
    }
    return SwitchListTile(
      value: _enabled!,
      title: Text(widget.label),
      onChanged: _update,
    );
  }
}
