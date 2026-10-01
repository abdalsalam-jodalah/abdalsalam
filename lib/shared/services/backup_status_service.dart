// lib/shared/services/backup_status_service.dart — stores and reads the backup timestamps outside the backed-up settings.

import '../../core/errors/app_error.dart';
import '../infrastructure/storage_gateway.dart';
import 'backup_status.dart';

class BackupStatusService {
  static const String storageKey = 'backup_status_v1';

  final StorageGateway storage;
  final DateTime Function() _clock;

  BackupStatusService(this.storage, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  Future<BackupStatus> read() async {
    final stored = await _readStored();
    if (stored.trackingStartedAt != null) {
      return stored;
    }
    final started = stored.copyWith(trackingStartedAt: _clock());
    await _write(started);
    return started;
  }

  Future<void> recordExported() async {
    final status = await read();
    await _write(status.copyWith(lastExportedAt: _clock()));
  }

  Future<void> recordAutoBackup() async {
    final status = await read();
    await _write(status.copyWith(lastAutoBackupAt: _clock()));
  }

  Future<int?> exportReminderDaysOverdue({required int reminderDays}) async {
    final status = await read();
    final now = _clock();
    return status.isExportReminderDue(reminderDays: reminderDays, now: now) ? status.daysSinceLastExport(now) : null;
  }

  Future<BackupStatus> _readStored() async {
    try {
      final stored = await storage.get<Map<String, dynamic>>(storageKey);
      return stored == null ? const BackupStatus() : BackupStatus.fromJson(stored);
    } on CorruptDataError {
      return const BackupStatus();
    }
  }

  Future<void> _write(BackupStatus status) => storage.save(key: storageKey, value: status.toJson());
}
