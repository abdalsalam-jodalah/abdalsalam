import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/sports/providers/sports_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sports_fakes.dart';

void main() {
  group('exerciseCategoriesProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseCategoryRepository()..shouldFailGetAllOrdered = true;
      final container = ProviderContainer(overrides: [
        exerciseCategoryRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(exerciseCategoriesProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the ordered categories on success', () async {
      final repo = FakeExerciseCategoryRepository([buildExerciseCategory(order: 1), buildExerciseCategory(id: 'c2', order: 0)]);
      final container = ProviderContainer(overrides: [
        exerciseCategoryRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final categories = await container.read(exerciseCategoriesProvider.future);
      expect(categories.map((category) => category.id), ['c2', 'category-1']);
    });
  });

  group('exercisesByCategoryProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseRepository()..shouldFailGetByCategory = true;
      final container = ProviderContainer(overrides: [
        exerciseRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(exercisesByCategoryProvider('category-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the matching exercises on success', () async {
      final repo = FakeExerciseRepository([buildExercise()]);
      final container = ProviderContainer(overrides: [
        exerciseRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final exercises = await container.read(exercisesByCategoryProvider('category-1').future);
      expect(exercises.map((exercise) => exercise.id), ['exercise-1']);
    });
  });

  group('allActiveExercisesProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        exerciseRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(allActiveExercisesProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns active exercises on success', () async {
      final repo = FakeExerciseRepository([buildExercise()]);
      final container = ProviderContainer(overrides: [
        exerciseRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final exercises = await container.read(allActiveExercisesProvider.future);
      expect(exercises.length, 1);
    });
  });

  group('scheduleForDayProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeWeeklyScheduleRepository()..shouldFailGetByDayOfWeek = true;
      final container = ProviderContainer(overrides: [
        weeklyScheduleRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(scheduleForDayProvider(DateTime.monday).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns entries for the day on success', () async {
      final repo = FakeWeeklyScheduleRepository([buildWeeklyScheduleEntry(dayOfWeek: DateTime.monday)]);
      final container = ProviderContainer(overrides: [
        weeklyScheduleRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final entries = await container.read(scheduleForDayProvider(DateTime.monday).future);
      expect(entries.length, 1);
    });
  });

  group('fullWeekScheduleProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeWeeklyScheduleRepository()..shouldFailGetFullWeek = true;
      final container = ProviderContainer(overrides: [
        weeklyScheduleRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(fullWeekScheduleProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the full week on success', () async {
      final repo = FakeWeeklyScheduleRepository([buildWeeklyScheduleEntry()]);
      final container = ProviderContainer(overrides: [
        weeklyScheduleRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final entries = await container.read(fullWeekScheduleProvider.future);
      expect(entries.length, 1);
    });
  });

  group('logsForDateProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseLogRepository()..shouldFailGetByDate = true;
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(logsForDateProvider(DateTime(2026, 1, 1)).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns logs for the date on success', () async {
      final repo = FakeExerciseLogRepository([buildExerciseLog(date: DateTime(2026, 1, 1))]);
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final logs = await container.read(logsForDateProvider(DateTime(2026, 1, 1)).future);
      expect(logs.length, 1);
    });
  });

  group('setsForLogProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseSetLogRepository()..shouldFailGetByExerciseLog = true;
      final container = ProviderContainer(overrides: [
        exerciseSetLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(setsForLogProvider('log-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns sets for the log on success', () async {
      final repo = FakeExerciseSetLogRepository([buildExerciseSetLog()]);
      final container = ProviderContainer(overrides: [
        exerciseSetLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final sets = await container.read(setsForLogProvider('log-1').future);
      expect(sets.length, 1);
    });
  });

  group('logsInRangeProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeExerciseLogRepository()..shouldFailGetByDateRange = true;
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(logsInRangeProvider((start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns logs in range on success', () async {
      final repo = FakeExerciseLogRepository([buildExerciseLog()]);
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final logs = await container.read(logsInRangeProvider((start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).future);
      expect(logs.length, 1);
    });
  });

  group('logsForExerciseInRangeProvider', () {
    test('returns only logs for the requested exercise', () async {
      final repo = FakeExerciseLogRepository([
        buildExerciseLog(id: 'log-1', exerciseId: 'exercise-1'),
        buildExerciseLog(id: 'log-2', exerciseId: 'exercise-2'),
      ]);
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final logs = await container.read(logsForExerciseInRangeProvider(
        (exerciseId: 'exercise-1', start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
      ).future);
      expect(logs.map((log) => log.id), ['log-1']);
    });

    test('propagates the underlying range failure', () async {
      final repo = FakeExerciseLogRepository()..shouldFailGetByDateRange = true;
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(logsForExerciseInRangeProvider(
          (exerciseId: 'exercise-1', start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        ).future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('setsForExerciseInRangeProvider', () {
    test('surfaces a typed error when the set log repository fails', () async {
      final logRepo = FakeExerciseLogRepository([buildExerciseLog(exerciseId: 'exercise-1')]);
      final setRepo = FakeExerciseSetLogRepository()..shouldFailGetByExerciseLogs = true;
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(logRepo),
        exerciseSetLogRepositoryProvider.overrideWithValue(setRepo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(setsForExerciseInRangeProvider(
          (exerciseId: 'exercise-1', start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        ).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns matching sets on success', () async {
      final logRepo = FakeExerciseLogRepository([buildExerciseLog(id: 'log-1', exerciseId: 'exercise-1')]);
      final setRepo = FakeExerciseSetLogRepository([buildExerciseSetLog(exerciseLogId: 'log-1')]);
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(logRepo),
        exerciseSetLogRepositoryProvider.overrideWithValue(setRepo),
      ]);
      addTearDown(container.dispose);

      final sets = await container.read(setsForExerciseInRangeProvider(
        (exerciseId: 'exercise-1', start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
      ).future);
      expect(sets.length, 1);
    });
  });

  group('personalRecordProvider', () {
    test('surfaces a typed error when the log repository fails', () async {
      final logRepo = FakeExerciseLogRepository()..shouldFailGetActive = true;
      final setRepo = FakeExerciseSetLogRepository();
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(logRepo),
        exerciseSetLogRepositoryProvider.overrideWithValue(setRepo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(personalRecordProvider('exercise-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('surfaces a typed error when the set log repository fails', () async {
      final logRepo = FakeExerciseLogRepository([buildExerciseLog(id: 'log-1', exerciseId: 'exercise-1')]);
      final setRepo = FakeExerciseSetLogRepository()..shouldFailGetByExerciseLogs = true;
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(logRepo),
        exerciseSetLogRepositoryProvider.overrideWithValue(setRepo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(personalRecordProvider('exercise-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the heaviest weight on success', () async {
      final logRepo = FakeExerciseLogRepository([buildExerciseLog(id: 'log-1', exerciseId: 'exercise-1')]);
      final setRepo = FakeExerciseSetLogRepository([
        buildExerciseSetLog(id: 'set-1', exerciseLogId: 'log-1', weightKg: 40),
        buildExerciseSetLog(id: 'set-2', exerciseLogId: 'log-1', weightKg: 60),
      ]);
      final container = ProviderContainer(overrides: [
        exerciseLogRepositoryProvider.overrideWithValue(logRepo),
        exerciseSetLogRepositoryProvider.overrideWithValue(setRepo),
      ]);
      addTearDown(container.dispose);

      final personalRecord = await container.read(personalRecordProvider('exercise-1').future);
      expect(personalRecord, 60);
    });
  });

  group('bodyMeasurementsInRangeProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeBodyMeasurementRepository()..shouldFailGetByDateRange = true;
      final container = ProviderContainer(overrides: [
        bodyMeasurementRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bodyMeasurementsInRangeProvider((start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns measurements in range on success', () async {
      final repo = FakeBodyMeasurementRepository([buildBodyMeasurement()]);
      final container = ProviderContainer(overrides: [
        bodyMeasurementRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final measurements = await container.read(
        bodyMeasurementsInRangeProvider((start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31))).future,
      );
      expect(measurements.length, 1);
    });
  });
}
