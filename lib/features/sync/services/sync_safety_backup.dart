// lib/features/sync/services/sync_safety_backup.dart — contract for writing a restorable backup before sync changes any data.

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';

abstract interface class SyncSafetyBackup {
  Future<Result<String, AppError>> create();
}
