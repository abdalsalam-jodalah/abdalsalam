import 'package:abdalsalam/data/models/sports/weekly_schedule_entry.dart';
import 'package:abdalsalam/data/repositories/sports/weekly_schedule_repository.dart';
import 'package:abdalsalam/features/sports/services/weekly_schedule_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingWeeklyScheduleRepository = WeeklyScheduleRepositoryImpl with FailingWrites<WeeklyScheduleEntry>;

WeeklyScheduleEntry _entry({
  String userId = 'u1',
  String exerciseId = 'exercise-1',
  int dayOfWeek = DateTime.monday,
  int order = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return WeeklyScheduleEntry(
    id: 'entry-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    dayOfWeek: dayOfWeek,
    exerciseId: exerciseId,
    order: order,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late WeeklyScheduleService service;

  setUp(() async {
    await resetTestStorage(
      databaseName: 'test_weekly_schedule_service_test.db',
      tables: ['sport_weekly_schedule'],
    );
    logger = LoggerService.forModule('WeeklyScheduleServiceTest');
    service = WeeklyScheduleService(WeeklyScheduleRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('WeeklyScheduleService.validate', () {
    test('should succeed for a Sunday entry', () {
      expect(service.validate(_entry(dayOfWeek: DateTime.sunday)).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_entry(userId: '')), WeeklyScheduleService.userIdField);
    });

    test('should report exerciseId when exerciseId is blank', () {
      expectFieldError(service.validate(_entry(exerciseId: '')), WeeklyScheduleService.exerciseIdField);
    });

    test('should report dayOfWeek when dayOfWeek is 0', () {
      expectFieldError(service.validate(_entry(dayOfWeek: 0)), WeeklyScheduleService.dayOfWeekField);
    });

    test('should report dayOfWeek when dayOfWeek is 8', () {
      expectFieldError(service.validate(_entry(dayOfWeek: 8)), WeeklyScheduleService.dayOfWeekField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_entry(order: -1)), WeeklyScheduleService.orderField);
    });
  });

  group('WeeklyScheduleService writes', () {
    test('should persist a created entry for its day', () async {
      final result = await service.create(_entry());

      expect(result.isSuccess, isTrue);
      final stored = await service.getByDayOfWeek(DateTime.monday);
      expect(stored.data?.map((entry) => entry.id), ['entry-1']);
    });

    test('should persist a reordered entry', () async {
      await service.create(_entry());

      final result = await service.updateBulk([_entry(order: 3)]);

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('entry-1');
      expect(stored.data?.order, 3);
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          WeeklyScheduleService(_FailingWeeklyScheduleRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_entry()));
    });

    test('should propagate a repository soft delete failure', () async {
      final failingService =
          WeeklyScheduleService(_FailingWeeklyScheduleRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.softDelete('entry-1'));
    });
  });
}
