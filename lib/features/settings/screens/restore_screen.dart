import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/restore_report.dart';
import '../../../shared/widgets/app_feedback.dart';

typedef _RunRestore = Future<Result<RestoreReport, AppError>> Function(bool replace);

class RestoreScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/restore';

  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const String _initialStatus = 'Choose a backup file or paste its contents to restore';
  static const String _restoringStatus = 'Restoring...';
  static const String _restoreCompleteStatus = 'Restore complete';
  static const String _restoreFailedStatus = 'Restore failed. Your existing data was not changed.';
  static const String _chooseFileLabel = 'Choose Backup File';
  static const String _restoreLabel = 'Restore Pasted Backup';
  static const String _replaceTitle = 'Replace existing data';
  static const String _replaceSubtitle = 'Clears every section in the backup before restoring it. Off: merge into current data.';
  static const String _confirmReplaceTitle = 'Replace existing data?';
  static const String _confirmReplaceMessage =
      'Every section included in this backup is cleared before it is restored. A safety backup is saved first.';
  static const String _confirmReplaceAction = 'Replace';
  static const String _cancelAction = 'Cancel';
  static const String _completeTitle = 'Restore complete';
  static const String _reloadAction = 'Reload app';

  final _controller = TextEditingController();
  String _status = _initialStatus;
  bool _isRestoring = false;
  bool _isReplaceMode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: const Text('Restore')),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Backup contents',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(_replaceTitle),
              subtitle: const Text(_replaceSubtitle),
              value: _isReplaceMode,
              onChanged: _isRestoring ? null : (value) => setState(() => _isReplaceMode = value),
            ),
            Align(alignment: Alignment.centerLeft, child: Text(_status)),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRestoring ? null : _restoreFromFile,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text(_chooseFileLabel),
                  ),
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _isRestoring
                        ? null
                        : () => _restore(
                              (replace) => ref.read(backupServiceProvider).restoreFromText(_controller.text, replace: replace),
                            ),
                    child: const Text(_restoreLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreFromFile() async {
    final picked = await FilePicker.platform.pickFiles();
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;
    final backupService = ref.read(backupServiceProvider);
    final content = await backupService.readBackupFile(path);
    if (!mounted) return;
    if (content.isFailure) {
      setState(() => _status = _restoreFailedStatus);
      AppFeedback.showError(context, content.error!);
      return;
    }
    await _restore((replace) => backupService.restoreFromBytes(content.data!, replace: replace));
  }

  Future<void> _restore(_RunRestore runRestore) async {
    final replace = _isReplaceMode;
    if (replace && !await _confirmReplace()) return;
    if (!mounted) return;
    setState(() {
      _isRestoring = true;
      _status = _restoringStatus;
    });
    final result = await runRestore(replace);
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (result.isFailure) {
      setState(() => _status = _restoreFailedStatus);
      AppFeedback.showError(context, result.error!);
      return;
    }
    setState(() => _status = _restoreCompleteStatus);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_completeTitle),
        content: Text(_describeReport(result.data!)),
        actions: [
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text(_reloadAction)),
        ],
      ),
    );
    if (!mounted) return;
    ref.read(appReloadProvider)();
  }

  Future<bool> _confirmReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_confirmReplaceTitle),
        content: const Text(_confirmReplaceMessage),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text(_cancelAction)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text(_confirmReplaceAction)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  String _describeReport(RestoreReport report) {
    final summary = StringBuffer(
      'Restored ${report.restoredRowCount} records from ${report.restoredTableCount} tables '
      'and ${report.restoredPreferenceCount} settings.',
    );
    if (report.restoredAttachmentCount > 0) {
      summary.write(' Restored ${report.restoredAttachmentCount} attachments.');
    }
    if (report.missingAttachmentCount > 0) {
      summary.write(' ${report.missingAttachmentCount} attachments were missing from the backup.');
    }
    if (report.skippedRowCount > 0) {
      summary.write(' Skipped ${report.skippedRowCount} invalid records.');
    }
    if (report.skippedUnknownTables.isNotEmpty) {
      summary.write(' Ignored unknown sections: ${report.skippedUnknownTables.join(', ')}.');
    }
    summary.write(' Safety backup saved to ${report.safetyBackupPath}.');
    return summary.toString();
  }
}
