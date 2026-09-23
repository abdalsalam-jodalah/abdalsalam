import 'package:abdalsalam/data/models/planning/goal.dart';
import 'package:abdalsalam/data/repositories/planning/goal_repository.dart';
import 'package:abdalsalam/features/planning/services/goal_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingGoalRepository = GoalRepositoryImpl with FailingWrites<Goal>;

Goal _goal({
  String id = 'goal-1',
  String userId = 'u1',
  String title = 'Run a marathon',
  double progress = 0.5,
  String? parentGoalId,
}) {
  final now = DateTime(2026, 1, 1);
  return Goal(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    scope: GoalScope.yearly,
    status: GoalStatus.notStarted,
    progress: progress,
    parentGoalId: parentGoalId,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late GoalService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_goal_service_test.db', tables: ['life_goals']);
    logger = LoggerService.forModule('GoalServiceTest');
    service = GoalService(GoalRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('GoalService.validate', () {
    test('should succeed for a well-formed goal', () {
      expect(service.validate(_goal()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_goal(userId: ' ')), GoalService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_goal(title: '')), GoalService.titleField);
    });

    test('should report progress when progress is above 1', () {
      expectFieldError(service.validate(_goal(progress: 1.5)), GoalService.progressField);
    });

    test('should report progress when progress is negative', () {
      expectFieldError(service.validate(_goal(progress: -0.1)), GoalService.progressField);
    });

    test('should report parentGoalId when a goal is its own parent', () {
      expectFieldError(service.validate(_goal(parentGoalId: 'goal-1')), GoalService.parentGoalIdField);
    });
  });

  group('GoalService writes', () {
    test('should persist a created goal', () async {
      final result = await service.create(_goal());

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('goal-1');
      expect(stored.data?.title, 'Run a marathon');
    });

    test('should persist an updated goal', () async {
      await service.create(_goal());

      final result = await service.update(_goal(title: 'Run two marathons'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('goal-1');
      expect(stored.data?.title, 'Run two marathons');
    });

    test('should not persist an invalid goal', () async {
      final result = await service.create(_goal(title: ''));

      expectFieldError(result, GoalService.titleField);
      final stored = await service.getById('goal-1');
      expect(stored.data, isNull);
    });

    test('should propagate a repository create failure', () async {
      final failingService = GoalService(_FailingGoalRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_goal()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = GoalService(_FailingGoalRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_goal()));
    });

    test('should propagate a repository soft delete failure', () async {
      final failingService = GoalService(_FailingGoalRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.softDelete('goal-1'));
    });
  });
}
