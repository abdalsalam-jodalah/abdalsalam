import 'package:abdalsalam/features/health/services/health_service.dart';
import 'package:abdalsalam/features/health/services/medication_daily_rollover_service.dart';
import 'package:abdalsalam/features/health/services/medication_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const lastRunKey = 'medication_daily_rollover_last_run';
  final storage = StorageGateway.instance;
  final today = DateTime(2026, 3, 1, 9);
  late FakeHealthRepository medications;
  late FakeMedicationLogRepository logs;
  late FakeReminderService reminders;
  late MedicationDailyRolloverService rollover;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_medication_daily_rollover_service_test.db');
    await storage.delete(lastRunKey);
    storage.integrityReporter.clearReports();
    final logger = LoggerService.forModule('MedicationDailyRolloverTest');
    medications = FakeHealthRepository([buildMedication()]);
    logs = FakeMedicationLogRepository();
    reminders = FakeReminderService();
    rollover = MedicationDailyRolloverService(
      medicationService: MedicationService(repository: medications, logger: logger, logRepository: logs),
      healthService: HealthService(medications, logger, reminders: reminders),
      healthRepository: medications,
      storage: storage,
      logger: logger,
      clock: () => today,
    );
  });

  group('MedicationDailyRolloverService.runIfNeeded', () {
    test('should generate logs, refresh reminders and run only once per day', () async {
      final first = await rollover.runIfNeeded(userId: 'user');
      final second = await rollover.runIfNeeded(userId: 'user');

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(logs.items, hasLength(1));
      expect(reminders.cancelledTargetIds, ['med-1']);
    });

    test('should return Failure and retry on the next run when log generation fails', () async {
      logs.shouldFailCreateBulk = true;

      final failed = await rollover.runIfNeeded(userId: 'user');
      logs.shouldFailCreateBulk = false;
      final retried = await rollover.runIfNeeded(userId: 'user');

      expect(failed.isFailure, isTrue);
      expect(retried.isSuccess, isTrue);
      expect(logs.items, hasLength(1));
    });

    test('should not mark the day as done when a reminder refresh fails', () async {
      reminders.shouldThrowOnSchedule = true;

      final result = await rollover.runIfNeeded(userId: 'user');

      expect(result.isFailure, isTrue);
      expect(await storage.get<String>(lastRunKey), isNull);
    });

    test('should return Failure when loading active medications fails', () async {
      medications.shouldFailGetActive = true;

      final result = await rollover.runIfNeeded(userId: 'user');

      expect(result.isFailure, isTrue);
      expect(await storage.get<String>(lastRunKey), isNull);
    });

    test('should treat a corrupt last-run marker as not run and report it', () async {
      await storage.save(key: lastRunKey, value: 42);

      final result = await rollover.runIfNeeded(userId: 'user');

      expect(result.isSuccess, isTrue);
      expect(logs.items, hasLength(1));
      expect(storage.integrityReporter.reports.single.recordId, lastRunKey);
      expect(await storage.get<String>(lastRunKey), '2026-03-01');
    });
  });
}
