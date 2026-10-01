import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/services/backup_archive.dart';
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
  static const String _initialStatus = 'No backup created yet';
  static const String _creatingStatus = 'Creating backup...';
  static const String _createFailedStatus = 'Backup failed';
  static const String _saveCancelledStatus = 'Save cancelled';
  static const String _shareFailedStatus = 'Share failed';
  static const String _sharedSuccessStatus = 'Backup shared successfully';
  static const String _guidance =
      'A backup holds every module, your settings, and attached files. Save it somewhere outside this phone '
      '(Google Drive, email, a computer) so it survives an uninstall or a lost device.';

  String _status = _initialStatus;
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const Text(_guidance),
          SizedBox(height: spacing.md),
          AppCard(child: Text(_status)),
          SizedBox(height: spacing.md),
          FilledButton.icon(
            onPressed: _isWorking ? null : _saveToDevice,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save to device'),
          ),
          SizedBox(height: spacing.sm),
          OutlinedButton.icon(
            onPressed: _isWorking ? null : _shareBackup,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share backup'),
          ),
        ],
      ),
    );
  }

  Future<BackupArchive?> _createArchive() async {
    setState(() {
      _isWorking = true;
      _status = _creatingStatus;
    });
    final backup = await ref.read(backupServiceProvider).createBackupArchive(
          tables: ref.read(backupTablesProvider),
        );
    if (!mounted) return null;
    if (backup.isFailure) {
      _finishWith(_createFailedStatus);
      AppFeedback.showError(context, backup.error!);
      return null;
    }
    return backup.data;
  }

  Future<void> _saveToDevice() async {
    final archive = await _createArchive();
    if (archive == null || !mounted) return;
    final saved = await ref.read(backupServiceProvider).saveBackupAs(
          bytes: archive.bytes,
          fileName: BackupService.backupFileName(DateTime.now()),
        );
    if (!mounted) return;
    if (saved.isFailure) {
      _finishWith(_createFailedStatus);
      AppFeedback.showError(context, saved.error!);
      return;
    }
    final path = saved.data;
    if (path != null) {
      _refreshBackupStatus();
    }
    _finishWith(path == null ? _saveCancelledStatus : 'Backup saved: $path${_attachmentNote(archive)}');
  }

  Future<void> _shareBackup() async {
    final archive = await _createArchive();
    if (archive == null || !mounted) return;
    final backupService = ref.read(backupServiceProvider);
    final saved = await backupService.saveBackupToDevice(
      bytes: archive.bytes,
      fileName: BackupService.backupFileName(DateTime.now()),
    );
    if (!mounted) return;
    if (saved.isFailure) {
      _finishWith(_createFailedStatus);
      AppFeedback.showError(context, saved.error!);
      return;
    }
    final shared = await backupService.shareBackup(saved.data!);
    if (!mounted) return;
    if (shared.isFailure) {
      _finishWith(_shareFailedStatus);
      AppFeedback.showError(context, shared.error!);
      return;
    }
    _refreshBackupStatus();
    _finishWith('$_sharedSuccessStatus${_attachmentNote(archive)}');
  }

  void _refreshBackupStatus() {
    ref.invalidate(backupReminderDaysProvider);
    ref.invalidate(backupStatusProvider);
  }

  void _finishWith(String status) {
    setState(() {
      _isWorking = false;
      _status = status;
    });
  }

  String _attachmentNote(BackupArchive archive) {
    if (archive.missingAttachmentCount == 0) {
      return '';
    }
    return ' (${archive.missingAttachmentCount} attached files could not be found and were left out)';
  }
}
