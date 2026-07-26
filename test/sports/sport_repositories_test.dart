import 'package:abdalsalam/data/models/sports/exercise.dart';
import 'package:abdalsalam/data/models/sports/exercise_log.dart';
import 'package:abdalsalam/data/models/sports/exercise_set_log.dart';
import 'package:abdalsalam/data/models/sports/weekly_schedule_entry.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_log_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_set_log_repository.dart';
import 'package:abdalsalam/data/repositories/sports/weekly_schedule_repository.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _userId = 'test-user';

Exercise _exercise(String id, {String categoryId = 'cat-1', int order = 0}) {
  final now = DateTime.now();
  return Exercise(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: _userId,
    name: 'Exercise $id',
    categoryId: categoryId,
    trackingType: ExerciseTrackingType.reps,
    order: order,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LoggerService logger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await StorageGateway.instance.initialize(databaseName: 'test_abdalsalam.db');
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
    for (final table in [
      'sport_exercise_categories',
      'sport_exercises',
      'sport_weekly_schedule',
      'sport_exercise_logs',
      'sport_exercise_set_logs',
      'sport_body_measurements',
    ]) {
      await StorageGateway.instance.clearTable(table);
    }
    logger = LoggerService.forModule('SportRepositoryTest');
  });

  group('ExerciseRepository', () {
    test('getByCategory returns only that category, sorted by order', () async {
      final repo = ExerciseRepositoryImpl(StorageGateway.instance, logger);
      await repo.create(_exercise('e2', categoryId: 'chest', order: 1));
      await repo.create(_exercise('e1', categoryId: 'chest', order: 0));
      await repo.create(_exercise('e3', categoryId: 'back', order: 0));

      final result = await repo.getByCategory('chest');

      expect(result.isSuccess, isTrue);
      expect(result.data!.map((e) => e.id).toList(), ['e1', 'e2']);
    });
  });

  group('WeeklyScheduleRepository', () {
    test('getByDayOfWeek filters by day and respects order', () async {
      final repo = WeeklyScheduleRepositoryImpl(StorageGateway.instance, logger);
      final now = DateTime.now();
      await repo.create(WeeklyScheduleEntry(
        id: 's1',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        dayOfWeek: 1,
        exerciseId: 'e1',
        order: 1,
      ));
      await repo.create(WeeklyScheduleEntry(
        id: 's2',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        dayOfWeek: 1,
        exerciseId: 'e2',
        order: 0,
      ));
      await repo.create(WeeklyScheduleEntry(
        id: 's3',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        dayOfWeek: 2,
        exerciseId: 'e3',
        order: 0,
      ));

      final monday = await repo.getByDayOfWeek(1);

      expect(monday.isSuccess, isTrue);
      expect(monday.data!.map((e) => e.id).toList(), ['s2', 's1']);
    });

    test('getByDayOfWeek excludes disabled entries', () async {
      final repo = WeeklyScheduleRepositoryImpl(StorageGateway.instance, logger);
      final now = DateTime.now();
      await repo.create(WeeklyScheduleEntry(
        id: 's1',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        dayOfWeek: 3,
        exerciseId: 'e1',
        enabled: false,
      ));

      final wednesday = await repo.getByDayOfWeek(3);

      expect(wednesday.data, isEmpty);
    });
  });

  group('ExerciseLogRepository', () {
    test('getByDate matches the logical date, not createdAt', () async {
      final repo = ExerciseLogRepositoryImpl(StorageGateway.instance, logger);
      final createdNow = DateTime.now();
      final loggedDate = DateTime(2026, 1, 15);
      await repo.create(ExerciseLog(
        id: 'l1',
        createdAt: createdNow,
        updatedAt: createdNow,
        userId: _userId,
        date: loggedDate,
        exerciseId: 'e1',
      ));

      final result = await repo.getByDate(loggedDate);

      expect(result.isSuccess, isTrue);
      expect(result.data!.single.id, 'l1');
    });

    test('getByDateRange (overridden) filters on ExerciseLog.date not createdAt', () async {
      final repo = ExerciseLogRepositoryImpl(StorageGateway.instance, logger);
      final createdNow = DateTime.now();
      await repo.create(ExerciseLog(
        id: 'past-log',
        createdAt: createdNow,
        updatedAt: createdNow,
        userId: _userId,
        date: DateTime(2020, 1, 1),
        exerciseId: 'e1',
      ));
      await repo.create(ExerciseLog(
        id: 'in-range',
        createdAt: createdNow,
        updatedAt: createdNow,
        userId: _userId,
        date: DateTime(2026, 6, 15),
        exerciseId: 'e2',
      ));

      final result = await repo.getByDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30));

      expect(result.isSuccess, isTrue);
      expect(result.data!.map((log) => log.id).toList(), ['in-range']);
    });
  });

  group('ExerciseSetLogRepository', () {
    test('getByExerciseLog sorts by setNumber', () async {
      final repo = ExerciseSetLogRepositoryImpl(StorageGateway.instance, logger);
      final now = DateTime.now();
      await repo.create(ExerciseSetLog(
        id: 'set2',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        exerciseLogId: 'log1',
        setNumber: 2,
        reps: 8,
      ));
      await repo.create(ExerciseSetLog(
        id: 'set1',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        exerciseLogId: 'log1',
        setNumber: 1,
        reps: 10,
      ));

      final result = await repo.getByExerciseLog('log1');

      expect(result.data!.map((s) => s.id).toList(), ['set1', 'set2']);
    });

    test('getByExerciseLogs joins across multiple log ids', () async {
      final repo = ExerciseSetLogRepositoryImpl(StorageGateway.instance, logger);
      final now = DateTime.now();
      await repo.create(ExerciseSetLog(
        id: 'a',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        exerciseLogId: 'log1',
        setNumber: 1,
        reps: 10,
        weightKg: 40,
      ));
      await repo.create(ExerciseSetLog(
        id: 'b',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        exerciseLogId: 'log2',
        setNumber: 1,
        reps: 10,
        weightKg: 45,
      ));
      await repo.create(ExerciseSetLog(
        id: 'c',
        createdAt: now,
        updatedAt: now,
        userId: _userId,
        exerciseLogId: 'log3',
        setNumber: 1,
        reps: 10,
        weightKg: 20,
      ));

      final result = await repo.getByExerciseLogs(['log1', 'log2']);

      expect(result.data!.map((s) => s.id).toSet(), {'a', 'b'});
    });
  });

  group('Reorder bulk-update', () {
    test('updateBulk persists new order values', () async {
      final repo = WeeklyScheduleRepositoryImpl(StorageGateway.instance, logger);
      final now = DateTime.now();
      final entries = [
        WeeklyScheduleEntry(
          id: 'r1',
          createdAt: now,
          updatedAt: now,
          userId: _userId,
          dayOfWeek: 5,
          exerciseId: 'e1',
          order: 0,
        ),
        WeeklyScheduleEntry(
          id: 'r2',
          createdAt: now,
          updatedAt: now,
          userId: _userId,
          dayOfWeek: 5,
          exerciseId: 'e2',
          order: 1,
        ),
      ];
      await repo.createBulk(entries);

      final reordered = [entries[1].copyWith(order: 0), entries[0].copyWith(order: 1)];
      await repo.updateBulk(reordered);

      final friday = await repo.getByDayOfWeek(5);
      expect(friday.data!.map((e) => e.id).toList(), ['r2', 'r1']);
    });
  });
}
