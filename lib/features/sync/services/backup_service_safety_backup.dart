// lib/features/sync/services/backup_service_safety_backup.dart — SyncSafetyBackup that saves a full backup archive through BackupService.

import '../../../core/constants/sync_constants.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/services/backup_service.dart';
import 'sync_safety_backup.dart';

class BackupServiceSafetyBackup implements SyncSafetyBackup {
  final BackupService backups;
  final DateTime Function() _clock;

  BackupServiceSafetyBackup(this.backups, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  @override
  Future<Result<String, AppError>> create() async {
    final archive = await backups.createBackupArchive(tables: backups.knownTables);
    if (archive.isFailure) {
      return Failure(archive.error!);
    }
    return backups.saveBackupToDevice(
      bytes: archive.data!.bytes,
      fileName:
          '${SyncConstants.safetyBackupFilePrefix}${_clock().millisecondsSinceEpoch}${SyncConstants.safetyBackupFileExtension}',
    );
  }
}
