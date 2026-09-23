import 'package:abdalsalam/data/models/planning/life_plan.dart';
import 'package:abdalsalam/data/repositories/planning/life_plan_repository.dart';
import 'package:abdalsalam/features/planning/services/life_plan_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingLifePlanRepository = LifePlanRepositoryImpl with FailingWrites<LifePlan>;

LifePlan _plan({String userId = 'u1', String visionStatement = 'Live with purpose'}) {
  final now = DateTime(2026, 1, 1);
  return LifePlan(
    id: 'plan-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    visionStatement: visionStatement,
    missionStatement: 'Build useful things',
    values: const ['Honesty'],
    principles: const ['Consistency'],
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late LifePlanService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_life_plan_service_test.db', tables: ['life_plans']);
    logger = LoggerService.forModule('LifePlanServiceTest');
    service = LifePlanService(LifePlanRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('LifePlanService.validate', () {
    test('should succeed for a well-formed plan', () {
      expect(service.validate(_plan()).isSuccess, isTrue);
    });

    test('should succeed when vision is empty because the screen allows drafts', () {
      expect(service.validate(_plan(visionStatement: '')).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_plan(userId: '')), LifePlanService.userIdField);
    });
  });

  group('LifePlanService writes', () {
    test('should persist a created plan', () async {
      final result = await service.create(_plan());

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('plan-1');
      expect(stored.data?.visionStatement, 'Live with purpose');
    });

    test('should persist an updated plan', () async {
      await service.create(_plan());

      final result = await service.update(_plan(visionStatement: 'Live deliberately'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('plan-1');
      expect(stored.data?.visionStatement, 'Live deliberately');
    });

    test('should propagate a repository create failure', () async {
      final failingService = LifePlanService(_FailingLifePlanRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_plan()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = LifePlanService(_FailingLifePlanRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_plan()));
    });
  });
}
