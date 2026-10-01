import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/backup_keys.dart';
import 'package:abdalsalam/shared/services/backup_status_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late DateTime now;
  late BackupStatusService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_backup_status_service_test.db');
    await storage.delete(BackupStatusService.storageKey);
    now = DateTime(2026, 10, 1, 9);
    service = BackupStatusService(storage, clock: () => now);
  });

  group('BackupStatusService', () {
    test('should start tracking on first read and keep the original start afterwards', () async {
      final first = await service.read();
      now = now.add(const Duration(days: 3));
      final second = await service.read();

      expect(first.trackingStartedAt, DateTime(2026, 10, 1, 9));
      expect(second.trackingStartedAt, DateTime(2026, 10, 1, 9));
    });

    test('should record when data was last saved outside the app', () async {
      await service.read();
      now = now.add(const Duration(days: 2));

      await service.recordExported();

      expect((await service.read()).lastExportedAt, DateTime(2026, 10, 3, 9));
    });

    test('should record automatic backups separately from exports', () async {
      await service.recordAutoBackup();

      final status = await service.read();
      expect(status.lastAutoBackupAt, DateTime(2026, 10, 1, 9));
      expect(status.lastExportedAt, isNull);
    });

    test('should report no reminder before the interval and the days elapsed after it', () async {
      await service.read();

      now = now.add(const Duration(days: 6));
      expect(await service.exportReminderDaysOverdue(reminderDays: 7), isNull);

      now = now.add(const Duration(days: 2));
      expect(await service.exportReminderDaysOverdue(reminderDays: 7), 8);
    });

    test('should clear the reminder after an export', () async {
      await service.read();
      now = now.add(const Duration(days: 10));
      await service.recordExported();

      expect(await service.exportReminderDaysOverdue(reminderDays: 7), isNull);
    });

    test('should start over instead of failing when the stored status is unreadable', () async {
      await storage.save(key: BackupStatusService.storageKey, value: 'not a map');

      final status = await service.read();

      expect(status.trackingStartedAt, DateTime(2026, 10, 1, 9));
    });

    test('should be left out of backups so a restore cannot roll it back', () {
      expect(BackupKeys.transientPreferenceKeys, contains(BackupStatusService.storageKey));
    });
  });
}
