import 'package:abdalsalam/data/models/sports/exercise_log.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_log_repository.dart';
import 'package:abdalsalam/features/sports/services/exercise_log_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingExerciseLogRepository = ExerciseLogRepositoryImpl with FailingWrites<ExerciseLog>;

final DateTime _logDate = DateTime(2026, 4, 2);

ExerciseLog _log({
  String userId = 'u1',
  String exerciseId = 'exercise-1',
  int order = 0,
  int? steps,
  int? durationSeconds,
  double? distanceKm,
}) {
  final now = DateTime(2026, 4, 2, 7);
  return ExerciseLog(
    id: 'log-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    date: _logDate,
    exerciseId: exerciseId,
    order: order,
    steps: steps,
    durationSeconds: durationSeconds,
    distanceKm: distanceKm,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late ExerciseLogService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_exercise_log_service_test.db', tables: ['sport_exercise_logs']);
    logger = LoggerService.forModule('ExerciseLogServiceTest');
    service = ExerciseLogService(ExerciseLogRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('ExerciseLogService.validate', () {
    test('should succeed for a well-formed log', () {
      expect(service.validate(_log(steps: 5000, durationSeconds: 1800, distanceKm: 4.2)).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_log(userId: '')), ExerciseLogService.userIdField);
    });

    test('should report exerciseId when exerciseId is blank', () {
      expectFieldError(service.validate(_log(exerciseId: '')), ExerciseLogService.exerciseIdField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_log(order: -1)), ExerciseLogService.orderField);
    });

    test('should report steps when steps is negative', () {
      expectFieldError(service.validate(_log(steps: -10)), ExerciseLogService.stepsField);
    });

    test('should report durationSeconds when durationSeconds is negative', () {
      expectFieldError(service.validate(_log(durationSeconds: -1)), ExerciseLogService.durationSecondsField);
    });

    test('should report distanceKm when distanceKm is negative', () {
      expectFieldError(service.validate(_log(distanceKm: -0.5)), ExerciseLogService.distanceKmField);
    });
  });

  group('ExerciseLogService writes', () {
    test('should persist a created log for its date', () async {
      final result = await service.create(_log());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByDate(_logDate);
      expect(stored.data?.map((log) => log.id), ['log-1']);
    });

    test('should persist updated cardio metrics', () async {
      await service.create(_log());

      final result = await service.update(_log(steps: 8000));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('log-1');
      expect(stored.data?.steps, 8000);
    });

    test('should not persist a cardio update with negative values', () async {
      await service.create(_log(steps: 100));

      final result = await service.update(_log(steps: -1));

      expectFieldError(result, ExerciseLogService.stepsField);
      final stored = await service.getById('log-1');
      expect(stored.data?.steps, 100);
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          ExerciseLogService(_FailingExerciseLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_log()));
    });

    test('should propagate a repository bulk update failure', () async {
      final failingService =
          ExerciseLogService(_FailingExerciseLogRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.updateBulk([_log()]));
    });
  });
}
