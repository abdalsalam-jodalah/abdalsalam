import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/reminder_service.dart';
import '../../../shared/widgets/app_feedback.dart';

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
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final settings = await ref.read(reminderServiceProvider).getModuleSettings();
      if (!mounted) return;
      setState(() => _enabled = settings[widget.module.name] ?? true);
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

  Future<void> _update(bool value) async {
    if (!mounted) return;
    try {
      await ref.read(reminderServiceProvider).setModuleEnabled(widget.module, value);
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
