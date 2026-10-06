import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/data/models/planning/task_category.dart';
import 'package:abdalsalam/data/repositories/planning/planning_task_repository.dart';
import 'package:abdalsalam/data/repositories/planning/task_category_repository.dart';
import 'package:abdalsalam/features/planning/services/task_category_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingPlanningTaskRepository = PlanningTaskRepositoryImpl with FailingWrites<PlanningTask>;

TaskCategory _category({
  String id = 'cat-1',
  String userId = 'u1',
  String name = 'iOS',
  String color = '#F5A623',
}) {
  final now = DateTime(2026, 3, 10, 8);
  return TaskCategory(id: id, createdAt: now, updatedAt: now, userId: userId, name: name, color: color);
}

PlanningTask _task({String id = 'task-1', List<String> categoryIds = const <String>[]}) {
  final now = DateTime(2026, 3, 10, 8);
  return PlanningTask(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: 'u1',
    title: 'Write report',
    date: DateTime(2026, 3, 10),
    categoryIds: categoryIds,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late PlanningTaskRepositoryImpl taskRepository;
  late TaskCategoryService service;

  setUp(() async {
    await resetTestStorage(
      databaseName: 'test_task_category_service_test.db',
      tables: ['planning_task_categories', 'life_planning_tasks'],
    );
    logger = LoggerService.forModule('TaskCategoryServiceTest');
    taskRepository = PlanningTaskRepositoryImpl(StorageGateway.instance, logger);
    service = TaskCategoryService(
      TaskCategoryRepositoryImpl(StorageGateway.instance, logger),
      logger,
      taskRepository: taskRepository,
    );
  });

  group('TaskCategoryService.validate', () {
    test('should succeed for a well-formed category', () {
      expect(service.validate(_category()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_category(userId: '')), TaskCategoryService.userIdField);
    });

    test('should report name when name is blank', () {
      expectFieldError(service.validate(_category(name: '  ')), TaskCategoryService.nameField);
    });

    test('should report name when it is longer than the limit', () {
      final tooLong = 'a' * (TaskCategoryService.maxNameLength + 1);

      expectFieldError(service.validate(_category(name: tooLong)), TaskCategoryService.nameField);
    });

    test('should accept a name exactly at the limit', () {
      final atLimit = 'a' * TaskCategoryService.maxNameLength;

      expect(service.validate(_category(name: atLimit)).isSuccess, isTrue);
    });

    test('should report color when it is not a #RRGGBB hex value', () {
      expectFieldError(service.validate(_category(color: 'orange')), TaskCategoryService.colorField);
      expectFieldError(service.validate(_category(color: '#FFF')), TaskCategoryService.colorField);
    });
  });

  group('TaskCategoryService writes', () {
    test('should persist a created category', () async {
      final result = await service.create(_category());

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('cat-1');
      expect(stored.data?.name, 'iOS');
      expect(stored.data?.color, '#F5A623');
    });

    test('should reject a second category with the same name ignoring case and spaces', () async {
      await service.create(_category());

      final result = await service.create(_category(id: 'cat-2', name: '  ios '));

      expectFieldError(result, TaskCategoryService.nameField);
      expect((await service.getActive()).data, hasLength(1));
    });

    test('should allow reusing the name of a deleted category', () async {
      await service.create(_category());
      await service.deleteAndDetach('cat-1');

      final result = await service.create(_category(id: 'cat-2'));

      expect(result.isSuccess, isTrue);
    });

    test('should allow saving a category under its own name', () async {
      await service.create(_category());

      final result = await service.update(_category(color: '#1D76DB'));

      expect(result.isSuccess, isTrue);
      expect((await service.getById('cat-1')).data?.color, '#1D76DB');
    });

    test('should reject renaming a category to a name another category uses', () async {
      await service.create(_category());
      await service.create(_category(id: 'cat-2', name: 'Work'));

      final result = await service.update(_category(id: 'cat-2', name: 'iOS'));

      expectFieldError(result, TaskCategoryService.nameField);
    });

    test('should list active categories sorted by name ignoring case', () async {
      await service.create(_category(id: 'c', name: 'work'));
      await service.create(_category(id: 'a', name: 'Android'));
      await service.create(_category(id: 'b', name: 'ios'));

      final sorted = await service.getActiveSortedByName();

      expect(sorted.data?.map((category) => category.name), ['Android', 'ios', 'work']);
    });
  });

  group('TaskCategoryService.deleteAndDetach', () {
    test('should remove the category and clear it from every task that used it', () async {
      await service.create(_category());
      await service.create(_category(id: 'cat-2', name: 'Work'));
      await taskRepository.create(_task(id: 'a', categoryIds: ['cat-1']));
      await taskRepository.create(_task(id: 'b', categoryIds: ['cat-1', 'cat-2']));
      await taskRepository.create(_task(id: 'c', categoryIds: ['cat-2']));

      final result = await service.deleteAndDetach('cat-1');

      expect(result.isSuccess, isTrue);
      expect((await service.getActive()).data?.map((category) => category.id), ['cat-2']);
      expect((await taskRepository.getById('a')).data?.categoryIds, isEmpty);
      expect((await taskRepository.getById('b')).data?.categoryIds, ['cat-2']);
      expect((await taskRepository.getById('c')).data?.categoryIds, ['cat-2']);
    });

    test('should succeed when no task uses the category', () async {
      await service.create(_category());

      expect((await service.deleteAndDetach('cat-1')).isSuccess, isTrue);
    });

    test('should report a failure when tasks cannot be detached but still remove the category', () async {
      await service.create(_category());
      await taskRepository.create(_task(categoryIds: ['cat-1']));
      final failingService = TaskCategoryService(
        TaskCategoryRepositoryImpl(StorageGateway.instance, logger),
        logger,
        taskRepository: _FailingPlanningTaskRepository(StorageGateway.instance, logger),
      );

      final result = await failingService.deleteAndDetach('cat-1');

      expectWriteFailure(result);
      expect((await service.getActive()).data, isEmpty);
    });
  });
}
