import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/services/restore_report.dart';
import '../../../shared/widgets/app_feedback.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/restore';

  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  static const String _initialStatus = 'Choose a backup file or paste its contents to restore';
  static const String _restoringStatus = 'Restoring...';
  static const String _restoreFailedStatus = 'Restore failed. Your existing data was not changed.';
  static const String _chooseFileLabel = 'Choose Backup File';
  static const String _restoreLabel = 'Restore Pasted Backup';

  final _controller = TextEditingController();
  String _status = _initialStatus;
  bool _isRestoring = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text(_status)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRestoring ? null : _restoreFromFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text(_chooseFileLabel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _isRestoring ? null : () => _restore(_controller.text),
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
    final content = await ref.read(backupServiceProvider).readBackupFile(path);
    if (!mounted) return;
    if (content.isFailure) {
      setState(() => _status = _restoreFailedStatus);
      AppFeedback.showError(context, content.error!);
      return;
    }
    await _restore(content.data!);
  }

  Future<void> _restore(String content) async {
    setState(() {
      _isRestoring = true;
      _status = _restoringStatus;
    });
    final result = await ref.read(backupServiceProvider).restoreFromText(content);
    if (!mounted) return;
    setState(() => _isRestoring = false);
    if (result.isFailure) {
      setState(() => _status = _restoreFailedStatus);
      AppFeedback.showError(context, result.error!);
      return;
    }
    setState(() => _status = _describeReport(result.data!));
  }

  String _describeReport(RestoreReport report) {
    final summary = StringBuffer(
      'Restored ${report.restoredRowCount} records from ${report.restoredTableCount} tables '
      'and ${report.restoredPreferenceCount} settings.',
    );
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
