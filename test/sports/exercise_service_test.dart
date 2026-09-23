import 'package:abdalsalam/data/models/sports/exercise.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_repository.dart';
import 'package:abdalsalam/features/sports/services/exercise_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingExerciseRepository = ExerciseRepositoryImpl with FailingWrites<Exercise>;

Exercise _exercise({
  String userId = 'u1',
  String name = 'Bench press',
  String categoryId = 'chest',
  int? defaultSets = 3,
  int? defaultReps = 10,
  double? defaultWeightKg = 40,
  int order = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Exercise(
    id: 'exercise-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    name: name,
    categoryId: categoryId,
    trackingType: ExerciseTrackingType.reps,
    defaultSets: defaultSets,
    defaultReps: defaultReps,
    defaultWeightKg: defaultWeightKg,
    order: order,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late ExerciseService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_exercise_service_test.db', tables: ['sport_exercises']);
    logger = LoggerService.forModule('ExerciseServiceTest');
    service = ExerciseService(ExerciseRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('ExerciseService.validate', () {
    test('should succeed for a well-formed exercise', () {
      expect(service.validate(_exercise()).isSuccess, isTrue);
    });

    test('should succeed when optional defaults are absent', () {
      final result = service.validate(_exercise(defaultSets: null, defaultReps: null, defaultWeightKg: null));
      expect(result.isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_exercise(userId: '')), ExerciseService.userIdField);
    });

    test('should report name when name is blank', () {
      expectFieldError(service.validate(_exercise(name: ' ')), ExerciseService.nameField);
    });

    test('should report categoryId when categoryId is blank', () {
      expectFieldError(service.validate(_exercise(categoryId: '')), ExerciseService.categoryIdField);
    });

    test('should report defaultSets when defaultSets is zero', () {
      expectFieldError(service.validate(_exercise(defaultSets: 0)), ExerciseService.defaultSetsField);
    });

    test('should report defaultReps when defaultReps is zero', () {
      expectFieldError(service.validate(_exercise(defaultReps: 0)), ExerciseService.defaultRepsField);
    });

    test('should report defaultWeightKg when defaultWeightKg is negative', () {
      expectFieldError(service.validate(_exercise(defaultWeightKg: -1)), ExerciseService.defaultWeightKgField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_exercise(order: -1)), ExerciseService.orderField);
    });
  });

  group('ExerciseService writes', () {
    test('should persist a created exercise in its category', () async {
      final result = await service.create(_exercise());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByCategory('chest');
      expect(stored.data?.map((exercise) => exercise.id), ['exercise-1']);
    });

    test('should persist an updated exercise', () async {
      await service.create(_exercise());

      final result = await service.update(_exercise(name: 'Incline bench press'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('exercise-1');
      expect(stored.data?.name, 'Incline bench press');
    });

    test('should propagate a repository create failure', () async {
      final failingService = ExerciseService(_FailingExerciseRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_exercise()));
    });

    test('should propagate a repository soft delete failure', () async {
      final failingService = ExerciseService(_FailingExerciseRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.softDelete('exercise-1'));
    });
  });
}
