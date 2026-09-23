import 'package:abdalsalam/data/models/sports/exercise_category.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_category_repository.dart';
import 'package:abdalsalam/features/sports/services/exercise_category_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingExerciseCategoryRepository = ExerciseCategoryRepositoryImpl with FailingWrites<ExerciseCategory>;

ExerciseCategory _category({String id = 'category-1', String userId = 'u1', String name = 'Chest', int order = 0}) {
  final now = DateTime(2026, 1, 1);
  return ExerciseCategory(id: id, createdAt: now, updatedAt: now, userId: userId, name: name, order: order);
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late ExerciseCategoryService service;

  setUp(() async {
    await resetTestStorage(
      databaseName: 'test_exercise_category_service_test.db',
      tables: ['sport_exercise_categories'],
    );
    logger = LoggerService.forModule('ExerciseCategoryServiceTest');
    service = ExerciseCategoryService(ExerciseCategoryRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('ExerciseCategoryService.validate', () {
    test('should succeed for a well-formed category', () {
      expect(service.validate(_category()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_category(userId: '')), ExerciseCategoryService.userIdField);
    });

    test('should report name when name is blank', () {
      expectFieldError(service.validate(_category(name: '')), ExerciseCategoryService.nameField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_category(order: -1)), ExerciseCategoryService.orderField);
    });
  });

  group('ExerciseCategoryService writes', () {
    test('should list created categories by order', () async {
      await service.create(_category(id: 'category-2', name: 'Back', order: 1));

      final result = await service.create(_category());

      expect(result.isSuccess, isTrue);
      final stored = await service.getAllOrdered();
      expect(stored.data?.map((category) => category.id), ['category-1', 'category-2']);
    });

    test('should persist a renamed category', () async {
      await service.create(_category());

      final result = await service.update(_category(name: 'Upper chest'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('category-1');
      expect(stored.data?.name, 'Upper chest');
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          ExerciseCategoryService(_FailingExerciseCategoryRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_category()));
    });

    test('should propagate a repository update failure', () async {
      final failingService =
          ExerciseCategoryService(_FailingExerciseCategoryRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_category()));
    });
  });
}
