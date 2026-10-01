import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/auto_backup_service.dart';
import 'package:abdalsalam/shared/services/backup_service.dart';
import 'package:abdalsalam/shared/services/backup_status_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeBackupService extends BackupService {
  int automaticBackupCount = 0;
  Result<String, AppError> result = const Success('/backups/abdalsalam-auto-1.zip');

  _FakeBackupService() : super(StorageGateway.instance, LoggerService.forModule('FakeBackupService'));

  @override
  Future<Result<String, AppError>> createAutomaticBackup() async {
    automaticBackupCount++;
    return result;
  }
}

class _FakeSettingsService extends SettingsService {
  Map<String, dynamic> values = <String, dynamic>{};

  _FakeSettingsService() : super(StorageGateway.instance);

  @override
  Future<Map<String, dynamic>> getSettings() async => values;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late DateTime now;
  late _FakeBackupService backups;
  late _FakeSettingsService settings;
  late BackupStatusService status;
  late AutoBackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_auto_backup_service_test.db');
    await storage.delete(BackupStatusService.storageKey);
    now = DateTime(2026, 10, 1, 9);
    backups = _FakeBackupService();
    settings = _FakeSettingsService();
    status = BackupStatusService(storage, clock: () => now);
    service = AutoBackupService(
      backups: backups,
      status: status,
      settings: settings,
      logger: LoggerService.forModule('AutoBackupServiceTest'),
      clock: () => now,
    );
  });

  group('AutoBackupService', () {
    test('should do nothing when automatic backup is switched off', () async {
      settings.values = {'autoBackupEnabled': false};

      final result = await service.runIfDue();

      expect(result.data, isFalse);
      expect(backups.automaticBackupCount, 0);
    });

    test('should back up straight away the first time it is switched on', () async {
      settings.values = {'autoBackupEnabled': true, 'backupReminderDays': 7};

      final result = await service.runIfDue();

      expect(result.data, isTrue);
      expect(backups.automaticBackupCount, 1);
      expect((await status.read()).lastAutoBackupAt, now);
    });

    test('should not back up again before the interval has passed', () async {
      settings.values = {'autoBackupEnabled': true, 'backupReminderDays': 7};
      await service.runIfDue();
      now = now.add(const Duration(days: 6));

      final result = await service.runIfDue();

      expect(result.data, isFalse);
      expect(backups.automaticBackupCount, 1);
    });

    test('should back up again once the interval has passed', () async {
      settings.values = {'autoBackupEnabled': true, 'backupReminderDays': 7};
      await service.runIfDue();
      now = now.add(const Duration(days: 7));

      final result = await service.runIfDue();

      expect(result.data, isTrue);
      expect(backups.automaticBackupCount, 2);
    });

    test('should use a seven day interval when the setting is missing', () async {
      settings.values = {'autoBackupEnabled': true};
      await service.runIfDue();
      now = now.add(const Duration(days: 6));
      await service.runIfDue();
      now = now.add(const Duration(days: 1));
      await service.runIfDue();

      expect(backups.automaticBackupCount, 2);
    });

    test('should report the failure and try again next time when the backup cannot be created', () async {
      settings.values = {'autoBackupEnabled': true, 'backupReminderDays': 7};
      backups.result = Failure(ExportError('disk full'));

      final result = await service.runIfDue();

      expect(result.error, isA<ExportError>());
      expect((await status.read()).lastAutoBackupAt, isNull);
    });
  });
}
