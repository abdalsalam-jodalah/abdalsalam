import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/backup_service.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';

class BackupScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings/backup';

  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  static const String _initialStatus = 'No backup started';
  static const String _creatingStatus = 'Creating backup...';
  static const String _createFailedStatus = 'Backup failed';
  static const String _shareFailedStatus = 'Share failed';
  static const String _sharedSuccessStatus = 'Backup shared successfully';

  String _status = _initialStatus;
  String? _lastPath;

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          AppCard(child: Text(_status)),
          SizedBox(height: spacing.md),
          FilledButton(
            onPressed: _createBackup,
            child: const Text('Create Full Backup'),
          ),
          SizedBox(height: spacing.sm),
          OutlinedButton(
            onPressed: _lastPath == null ? null : _shareBackup,
            child: const Text('Share Last Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _status = _creatingStatus);
    final backup = await ref.read(backupServiceProvider).createCompressedBackup(
          tables: ref.read(backupTablesProvider),
        );
    if (!mounted) return;
    if (backup.isFailure) {
      setState(() => _status = _createFailedStatus);
      AppFeedback.showError(context, backup.error!);
      return;
    }

    final save = await ref.read(backupServiceProvider).saveBackupToDevice(
          content: backup.data!,
          fileName: BackupService.backupFileName(DateTime.now()),
        );
    if (!mounted) return;
    if (save.isFailure) {
      setState(() => _status = _createFailedStatus);
      AppFeedback.showError(context, save.error!);
      return;
    }
    setState(() {
      _lastPath = save.data;
      _status = 'Backup saved: ${save.data}';
    });
  }

  Future<void> _shareBackup() async {
    final path = _lastPath;
    if (path == null) return;
    final share = await ref.read(backupServiceProvider).shareBackup(path);
    if (!mounted) return;
    if (share.isFailure) {
      setState(() => _status = _shareFailedStatus);
      AppFeedback.showError(context, share.error!);
      return;
    }
    setState(() => _status = _sharedSuccessStatus);
  }
}
