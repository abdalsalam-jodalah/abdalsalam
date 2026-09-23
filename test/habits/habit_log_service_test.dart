import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:abdalsalam/data/repositories/habits/habit_log_repository.dart';
import 'package:abdalsalam/features/habits/services/habit_log_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingHabitLogRepository = HabitLogRepositoryImpl with FailingWrites<HabitLog>;

HabitLog _log({String userId = 'u1', String habitId = 'habit-1', int? intensity = 3, String? notes}) {
  final now = DateTime(2026, 6, 1, 9);
  return HabitLog(
    id: 'log-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    habitId: habitId,
    completedAt: now,
    intensity: intensity,
    notes: notes,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late HabitLogService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_habit_log_service_test.db', tables: ['habit_logs']);
    logger = LoggerService.forModule('HabitLogServiceTest');
    service = HabitLogService(HabitLogRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('HabitLogService.validate', () {
    test('should succeed for a well-formed log', () {
      expect(service.validate(_log()).isSuccess, isTrue);
    });

    test('should succeed when intensity is absent for a good habit', () {
      expect(service.validate(_log(intensity: null)).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_log(userId: '')), HabitLogService.userIdField);
    });

    test('should report habitId when habitId is blank', () {
      expectFieldError(service.validate(_log(habitId: '')), HabitLogService.habitIdField);
    });

    test('should report intensity when intensity is below 1', () {
      expectFieldError(service.validate(_log(intensity: 0)), HabitLogService.intensityField);
    });

    test('should report intensity when intensity is above 5', () {
      expectFieldError(service.validate(_log(intensity: 6)), HabitLogService.intensityField);
    });
  });

  group('HabitLogService writes', () {
    test('should persist a created log for its habit', () async {
      final result = await service.create(_log());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByHabit('habit-1');
      expect(stored.data?.map((log) => log.id), ['log-1']);
    });

    test('should persist an updated log', () async {
      await service.create(_log());

      final result = await service.update(_log(notes: 'Felt great'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('log-1');
      expect(stored.data?.notes, 'Felt great');
    });

    test('should propagate a repository create failure', () async {
      final failingService = HabitLogService(_FailingHabitLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_log()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = HabitLogService(_FailingHabitLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_log()));
    });
  });
}
