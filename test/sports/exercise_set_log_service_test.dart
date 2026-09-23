import 'package:abdalsalam/data/models/sports/exercise_set_log.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_set_log_repository.dart';
import 'package:abdalsalam/features/sports/services/exercise_set_log_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingExerciseSetLogRepository = ExerciseSetLogRepositoryImpl with FailingWrites<ExerciseSetLog>;

ExerciseSetLog _set({
  String id = 'set-1',
  String userId = 'u1',
  String exerciseLogId = 'log-1',
  int setNumber = 1,
  int reps = 10,
  double? weightKg = 50,
}) {
  final now = DateTime(2026, 4, 2, 7);
  return ExerciseSetLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    exerciseLogId: exerciseLogId,
    setNumber: setNumber,
    reps: reps,
    weightKg: weightKg,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late ExerciseSetLogService service;

  setUp(() async {
    await resetTestStorage(
      databaseName: 'test_exercise_set_log_service_test.db',
      tables: ['sport_exercise_set_logs'],
    );
    logger = LoggerService.forModule('ExerciseSetLogServiceTest');
    service = ExerciseSetLogService(ExerciseSetLogRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('ExerciseSetLogService.validate', () {
    test('should succeed for a well-formed set', () {
      expect(service.validate(_set()).isSuccess, isTrue);
    });

    test('should succeed for a bodyweight set with zero weight', () {
      expect(service.validate(_set(weightKg: 0)).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_set(userId: '')), ExerciseSetLogService.userIdField);
    });

    test('should report exerciseLogId when exerciseLogId is blank', () {
      expectFieldError(service.validate(_set(exerciseLogId: '')), ExerciseSetLogService.exerciseLogIdField);
    });

    test('should report setNumber when setNumber is zero', () {
      expectFieldError(service.validate(_set(setNumber: 0)), ExerciseSetLogService.setNumberField);
    });

    test('should report reps when reps is zero', () {
      expectFieldError(service.validate(_set(reps: 0)), ExerciseSetLogService.repsField);
    });

    test('should report weightKg when weightKg is negative', () {
      expectFieldError(service.validate(_set(weightKg: -5)), ExerciseSetLogService.weightKgField);
    });
  });

  group('ExerciseSetLogService writes', () {
    test('should persist created sets ordered by set number', () async {
      await service.create(_set(id: 'set-2', setNumber: 2));

      final result = await service.create(_set());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByExerciseLog('log-1');
      expect(stored.data?.map((set) => set.setNumber), [1, 2]);
    });

    test('should persist an updated set', () async {
      await service.create(_set());

      final result = await service.update(_set(reps: 12));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('set-1');
      expect(stored.data?.reps, 12);
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          ExerciseSetLogService(_FailingExerciseSetLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_set()));
    });

    test('should propagate a repository update failure', () async {
      final failingService =
          ExerciseSetLogService(_FailingExerciseSetLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_set()));
    });
  });
}
