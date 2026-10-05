// test/sync/support/fake_sync_safety_backup.dart — SyncSafetyBackup fake that counts calls and can be told to fail.

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/features/sync/services/sync_safety_backup.dart';

class FakeSyncSafetyBackup implements SyncSafetyBackup {
  static const String savedPath = '/backups/pre-sync.zip';

  bool isFailing = false;
  int createCount = 0;

  @override
  Future<Result<String, AppError>> create() async {
    createCount++;
    if (isFailing) {
      return Failure(ExportError('disk full'));
    }
    return const Success(savedPath);
  }
}
