import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/module_export.dart';
import '../../../shared/services/module_table_registry.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/data/export';

  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  static const String _guidance =
      'Creates a zip with one folder per module: a JSON file and a CSV per table you can open in a spreadsheet '
      'or feed to an analysis tool. Financial transactions include account and category names. '
      'Saved passwords are never exported. This file is for reading, not for restoring; use Backup for that.';
  static const String _initialStatus = 'Choose what to export';
  static const String _buildingStatus = 'Building export...';
  static const String _failedStatus = 'Export failed';
  static const String _cancelledStatus = 'Save cancelled';
  static const String _sharedStatus = 'Export shared successfully';

  final List<DataModule> _modules = ModuleTableRegistry.readableExportModules;
  late final Set<DataModule> _selected = _modules.toSet();
  bool _includeDeleted = false;
  bool _isWorking = false;
  String _status = _initialStatus;

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    final canExport = _selected.isNotEmpty && !_isWorking;
    final counts = ref.watch(recordCountsByModuleProvider).maybeWhen(
          data: (values) => values,
          orElse: () => const <DataModule, int>{},
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Export for analysis')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const Text(_guidance),
          SizedBox(height: spacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final module in _modules)
                  CheckboxListTile(
                    value: _selected.contains(module),
                    title: Text(module.label),
                    subtitle: Text('${counts[module] ?? 0} records'),
                    onChanged: _isWorking ? null : (value) => _toggle(module, value ?? false),
                  ),
                SwitchListTile(
                  value: _includeDeleted,
                  title: const Text('Include deleted records'),
                  subtitle: const Text('Records you removed but the app still keeps'),
                  onChanged: _isWorking ? null : (value) => setState(() => _includeDeleted = value),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.md),
          AppCard(child: Text(_status)),
          SizedBox(height: spacing.md),
          FilledButton.icon(
            onPressed: canExport ? _saveToDevice : null,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save to device'),
          ),
          SizedBox(height: spacing.sm),
          OutlinedButton.icon(
            onPressed: canExport ? _share : null,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share export'),
          ),
        ],
      ),
    );
  }

  void _toggle(DataModule module, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selected.add(module);
      } else {
        _selected.remove(module);
      }
    });
  }

  Future<ModuleExport?> _build() async {
    setState(() {
      _isWorking = true;
      _status = _buildingStatus;
    });
    final built = await ref.read(moduleExportServiceProvider).export(
          modules: _selected,
          includeDeleted: _includeDeleted,
        );
    if (!mounted) return null;
    if (built.isFailure) {
      _finishWith(_failedStatus);
      AppFeedback.showError(context, built.error!);
      return null;
    }
    return built.data;
  }

  Future<void> _saveToDevice() async {
    final export = await _build();
    if (export == null || !mounted) return;
    final saved = await ref.read(moduleExportServiceProvider).saveExportAs(export);
    if (!mounted) return;
    if (saved.isFailure) {
      _finishWith(_failedStatus);
      AppFeedback.showError(context, saved.error!);
      return;
    }
    final path = saved.data;
    _finishWith(path == null ? _cancelledStatus : 'Export saved: $path');
  }

  Future<void> _share() async {
    final export = await _build();
    if (export == null || !mounted) return;
    final shared = await ref.read(moduleExportServiceProvider).shareExport(export);
    if (!mounted) return;
    if (shared.isFailure) {
      _finishWith(_failedStatus);
      AppFeedback.showError(context, shared.error!);
      return;
    }
    _finishWith(_sharedStatus);
  }

  void _finishWith(String status) {
    setState(() {
      _isWorking = false;
      _status = status;
    });
  }
}
