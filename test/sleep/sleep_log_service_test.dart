import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:abdalsalam/data/repositories/sleep/sleep_log_repository.dart';
import 'package:abdalsalam/features/sleep/services/sleep_log_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const uuid = Uuid();

  SleepLog buildLog({
    DateTime? sleepStart,
    DateTime? sleepEnd,
    int? feelingBeforeSleep,
    int? feelingOnWakeup,
    int? feelingDuringDay,
  }) {
    final now = DateTime.now();
    final start = sleepStart ?? DateTime(now.year, now.month, now.day, 23, 0).subtract(const Duration(days: 1));
    final end = sleepEnd ?? DateTime(now.year, now.month, now.day, 7, 0);
    return SleepLog(
      id: uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'u1',
      sleepStart: start,
      sleepEnd: end,
      feelingBeforeSleep: feelingBeforeSleep,
      feelingOnWakeup: feelingOnWakeup,
      feelingDuringDay: feelingDuringDay,
    );
  }

  group('SleepLogService', () {
    late SleepLogService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_sleep_log_service_test.db');
      await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
      await StorageGateway.instance.clearTable('sleep_logs');
      final logger = LoggerService.forModule('SleepLogServiceTest');
      final SleepLogRepository repository = SleepLogRepositoryImpl(StorageGateway.instance, logger);
      service = SleepLogService(repository, logger);
    });

    test('validate succeeds for a well-formed log', () {
      final result = service.validate(buildLog(feelingBeforeSleep: 3, feelingOnWakeup: 4));
      expect(result.isSuccess, isTrue);
    });

    test('validate fails when sleepEnd is not after sleepStart', () {
      final result = service.validate(buildLog(
        sleepStart: DateTime(2026, 7, 26, 7, 0),
        sleepEnd: DateTime(2026, 7, 25, 23, 0),
      ));
      expect(result.isFailure, isTrue);
    });

    test('validate fails when a rating is out of range', () {
      final result = service.validate(buildLog(feelingOnWakeup: 6));
      expect(result.isFailure, isTrue);
    });

    test('create rejects an invalid log before hitting storage', () async {
      final result = await service.create(buildLog(
        sleepStart: DateTime(2026, 7, 26, 7, 0),
        sleepEnd: DateTime(2026, 7, 25, 23, 0),
      ));
      expect(result.isFailure, isTrue);
    });

    test('getStatistics reports average duration and feelings', () async {
      final created = await service.create(buildLog(feelingOnWakeup: 4));
      expect(created.isSuccess, isTrue);

      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 1);
      expect(stats.data?['averageDurationMinutesLast7Days'], 8 * 60);
      expect(stats.data?['averageFeelingOnWakeup'], 4.0);
    });

    test('getStatistics returns null averages when there are no logs', () async {
      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 0);
      expect(stats.data?['averageDurationMinutesLast7Days'], isNull);
      expect(stats.data?['mostRecentLog'], isNull);
    });
  });
}
