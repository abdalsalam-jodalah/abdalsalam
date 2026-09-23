import 'package:abdalsalam/data/models/planning/planning_task.dart';
import 'package:abdalsalam/data/repositories/planning/planning_task_repository.dart';
import 'package:abdalsalam/features/planning/services/planning_task_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingPlanningTaskRepository = PlanningTaskRepositoryImpl with FailingWrites<PlanningTask>;

final DateTime _taskDate = DateTime(2026, 3, 10);

PlanningTask _task({
  String id = 'task-1',
  String userId = 'u1',
  String title = 'Write report',
  int order = 0,
  bool isCompleted = false,
}) {
  final now = DateTime(2026, 3, 10, 8);
  return PlanningTask(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    order: order,
    isCompleted: isCompleted,
    date: _taskDate,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late PlanningTaskService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_planning_task_service_test.db', tables: ['life_planning_tasks']);
    logger = LoggerService.forModule('PlanningTaskServiceTest');
    service = PlanningTaskService(PlanningTaskRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('PlanningTaskService.validate', () {
    test('should succeed for a well-formed task', () {
      expect(service.validate(_task()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_task(userId: '')), PlanningTaskService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_task(title: '')), PlanningTaskService.titleField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_task(order: -1)), PlanningTaskService.orderField);
    });
  });

  group('PlanningTaskService writes', () {
    test('should persist a created task for its date', () async {
      final result = await service.create(_task());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByDate(_taskDate);
      expect(stored.data?.map((task) => task.id), ['task-1']);
    });

    test('should persist a completed toggle', () async {
      await service.create(_task());

      final result = await service.update(_task(isCompleted: true));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('task-1');
      expect(stored.data?.isCompleted, isTrue);
    });

    test('should reject a reorder batch containing an invalid task', () async {
      final result = await service.updateBulk([_task(), _task(id: 'task-2', title: '')]);

      expectFieldError(result, PlanningTaskService.titleField);
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          PlanningTaskService(_FailingPlanningTaskRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_task()));
    });

    test('should propagate a repository bulk update failure', () async {
      final failingService =
          PlanningTaskService(_FailingPlanningTaskRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.updateBulk([_task()]));
    });
  });
}
