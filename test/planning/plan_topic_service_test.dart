import 'package:abdalsalam/data/models/planning/plan_topic.dart';
import 'package:abdalsalam/data/repositories/planning/plan_topic_repository.dart';
import 'package:abdalsalam/features/planning/services/plan_topic_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingPlanTopicRepository = PlanTopicRepositoryImpl with FailingWrites<PlanTopic>;

PlanTopic _topic({
  String id = 'topic-1',
  String userId = 'u1',
  String title = 'Health',
  String? parentTopicId,
}) {
  final now = DateTime(2026, 1, 1);
  return PlanTopic(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    parentTopicId: parentTopicId,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late PlanTopicService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_plan_topic_service_test.db', tables: ['life_plan_topics']);
    logger = LoggerService.forModule('PlanTopicServiceTest');
    service = PlanTopicService(PlanTopicRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('PlanTopicService.validate', () {
    test('should succeed for a well-formed topic', () {
      expect(service.validate(_topic()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_topic(userId: '')), PlanTopicService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_topic(title: '  ')), PlanTopicService.titleField);
    });

    test('should report parentTopicId when a topic is its own parent', () {
      expectFieldError(service.validate(_topic(parentTopicId: 'topic-1')), PlanTopicService.parentTopicIdField);
    });
  });

  group('PlanTopicService writes', () {
    test('should persist a created sub-topic and list it under its parent', () async {
      await service.create(_topic());

      final result = await service.create(_topic(id: 'topic-2', title: 'Sleep', parentTopicId: 'topic-1'));

      expect(result.isSuccess, isTrue);
      final children = await service.getChildren('topic-1');
      expect(children.data?.map((topic) => topic.id), ['topic-2']);
      final roots = await service.getRootTopics();
      expect(roots.data?.map((topic) => topic.id), ['topic-1']);
    });

    test('should persist an updated topic', () async {
      await service.create(_topic());

      final result = await service.update(_topic(title: 'Fitness'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('topic-1');
      expect(stored.data?.title, 'Fitness');
    });

    test('should propagate a repository create failure', () async {
      final failingService = PlanTopicService(_FailingPlanTopicRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_topic()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = PlanTopicService(_FailingPlanTopicRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_topic()));
    });
  });
}
