import 'package:abdalsalam/data/models/planning/achievement.dart';
import 'package:abdalsalam/data/repositories/planning/achievement_repository.dart';
import 'package:abdalsalam/features/planning/services/achievement_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingAchievementRepository = AchievementRepositoryImpl with FailingWrites<Achievement>;

Achievement _achievement({String userId = 'u1', String title = 'Finished first 10k', String? goalId = 'goal-1'}) {
  final now = DateTime(2026, 2, 1);
  return Achievement(
    id: 'achievement-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    achievedAt: now,
    goalId: goalId,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late AchievementService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_achievement_service_test.db', tables: ['life_achievements']);
    logger = LoggerService.forModule('AchievementServiceTest');
    service = AchievementService(AchievementRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('AchievementService.validate', () {
    test('should succeed for a well-formed achievement', () {
      expect(service.validate(_achievement()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_achievement(userId: '')), AchievementService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_achievement(title: '')), AchievementService.titleField);
    });
  });

  group('AchievementService writes', () {
    test('should persist a created achievement linked to its goal', () async {
      final result = await service.create(_achievement());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByGoal('goal-1');
      expect(stored.data?.map((achievement) => achievement.title), ['Finished first 10k']);
    });

    test('should persist an updated achievement', () async {
      await service.create(_achievement());

      final result = await service.update(_achievement(title: 'Finished first half marathon'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('achievement-1');
      expect(stored.data?.title, 'Finished first half marathon');
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          AchievementService(_FailingAchievementRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_achievement()));
    });

    test('should propagate a repository update failure', () async {
      final failingService =
          AchievementService(_FailingAchievementRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_achievement()));
    });
  });
}
