import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/wellness_reminder_rollover_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../health/health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const lastRunKey = 'wellness_reminder_rollover_last_run';
  final storage = StorageGateway.instance;
  final today = DateTime(2026, 3, 1, 9);
  late FakeReminderService reminders;
  late WellnessReminderRolloverService rollover;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_wellness_reminder_rollover_service_test.db');
    await storage.delete(lastRunKey);
    storage.integrityReporter.clearReports();
    reminders = FakeReminderService();
    rollover = WellnessReminderRolloverService(
      reminderService: reminders,
      storage: storage,
      logger: LoggerService.forModule('WellnessReminderRolloverTest'),
      clock: () => today,
    );
  });

  group('WellnessReminderRolloverService.runIfNeeded', () {
    test('should schedule sleep and food reminders once per day', () async {
      final first = await rollover.runIfNeeded();
      final second = await rollover.runIfNeeded();

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(reminders.scheduled, hasLength(2));
    });

    test('should return Failure and leave the day unmarked when scheduling fails', () async {
      reminders.shouldThrowOnSchedule = true;

      final result = await rollover.runIfNeeded();

      expect(result.isFailure, isTrue);
      expect(await storage.get<String>(lastRunKey), isNull);
    });

    test('should treat a corrupt last-run marker as not run and report it', () async {
      await storage.save(key: lastRunKey, value: 42);

      final result = await rollover.runIfNeeded();

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled, hasLength(2));
      expect(storage.integrityReporter.reports.single.recordId, lastRunKey);
    });
  });
}
