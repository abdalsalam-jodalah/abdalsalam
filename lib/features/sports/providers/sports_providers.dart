import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/sports/body_measurement.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/models/sports/exercise_category.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../data/models/sports/exercise_set_log.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
import '../../../data/repositories/sports/body_measurement_repository.dart';
import '../../../data/repositories/sports/exercise_category_repository.dart';
import '../../../data/repositories/sports/exercise_log_repository.dart';
import '../../../data/repositories/sports/exercise_repository.dart';
import '../../../data/repositories/sports/exercise_set_log_repository.dart';
import '../../../data/repositories/sports/weekly_schedule_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';

const String sportUserId = 'user1';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// Repository Providers
final exerciseCategoryRepositoryProvider = Provider<ExerciseCategoryRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'ExerciseCategoryRepository',
    moduleType: logic.ModuleType.repository,
  );
  return ExerciseCategoryRepositoryImpl(storage, logger);
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'ExerciseRepository',
    moduleType: logic.ModuleType.repository,
  );
  return ExerciseRepositoryImpl(storage, logger);
});

final weeklyScheduleRepositoryProvider = Provider<WeeklyScheduleRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'WeeklyScheduleRepository',
    moduleType: logic.ModuleType.repository,
  );
  return WeeklyScheduleRepositoryImpl(storage, logger);
});

final exerciseLogRepositoryProvider = Provider<ExerciseLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'ExerciseLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return ExerciseLogRepositoryImpl(storage, logger);
});

final exerciseSetLogRepositoryProvider = Provider<ExerciseSetLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'ExerciseSetLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return ExerciseSetLogRepositoryImpl(storage, logger);
});

final bodyMeasurementRepositoryProvider = Provider<BodyMeasurementRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'BodyMeasurementRepository',
    moduleType: logic.ModuleType.repository,
  );
  return BodyMeasurementRepositoryImpl(storage, logger);
});

// Catalog Providers
final exerciseCategoriesProvider = FutureProvider<List<ExerciseCategory>>((ref) async {
  final repo = ref.watch(exerciseCategoryRepositoryProvider);
  final result = await repo.getAllOrdered();
  return result.data ?? [];
});

final exercisesByCategoryProvider =
    FutureProvider.family<List<Exercise>, String>((ref, categoryId) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getByCategory(categoryId);
  return result.data ?? [];
});

final allActiveExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  final result = await repo.getActive();
  return result.data ?? [];
});

// Weekly Schedule Providers
final scheduleForDayProvider =
    FutureProvider.family<List<WeeklyScheduleEntry>, int>((ref, dayOfWeek) async {
  final repo = ref.watch(weeklyScheduleRepositoryProvider);
  final result = await repo.getByDayOfWeek(dayOfWeek);
  return result.data ?? [];
});

final fullWeekScheduleProvider = FutureProvider<List<WeeklyScheduleEntry>>((ref) async {
  final repo = ref.watch(weeklyScheduleRepositoryProvider);
  final result = await repo.getFullWeek();
  return result.data ?? [];
});

// Daily Log Providers
final logsForDateProvider = FutureProvider.family<List<ExerciseLog>, DateTime>((ref, date) async {
  final repo = ref.watch(exerciseLogRepositoryProvider);
  final result = await repo.getByDate(dateOnly(date));
  return result.data ?? [];
});

final setsForLogProvider = FutureProvider.family<List<ExerciseSetLog>, String>((ref, logId) async {
  final repo = ref.watch(exerciseSetLogRepositoryProvider);
  final result = await repo.getByExerciseLog(logId);
  return result.data ?? [];
});

typedef DateRangeQuery = ({DateTime start, DateTime end});

final logsInRangeProvider =
    FutureProvider.family<List<ExerciseLog>, DateRangeQuery>((ref, range) async {
  final repo = ref.watch(exerciseLogRepositoryProvider);
  final result = await repo.getByDateRange(range.start, range.end);
  return result.data ?? [];
});

typedef ExerciseRangeQuery = ({String exerciseId, DateTime start, DateTime end});

final logsForExerciseInRangeProvider =
    FutureProvider.family<List<ExerciseLog>, ExerciseRangeQuery>((ref, query) async {
  final logs = await ref.watch(
    logsInRangeProvider((start: query.start, end: query.end)).future,
  );
  return logs.where((log) => log.exerciseId == query.exerciseId).toList(growable: false);
});

final setsForExerciseInRangeProvider =
    FutureProvider.family<List<ExerciseSetLog>, ExerciseRangeQuery>((ref, query) async {
  final logs = await ref.watch(logsForExerciseInRangeProvider(query).future);
  if (logs.isEmpty) {
    return const [];
  }
  final repo = ref.watch(exerciseSetLogRepositoryProvider);
  final result = await repo.getByExerciseLogs(logs.map((log) => log.id).toList());
  return result.data ?? [];
});

/// Best all-time [ExerciseSetLog.weightKg] for a strength exercise, used to
/// flag personal records while logging.
final personalRecordProvider = FutureProvider.family<double?, String>((ref, exerciseId) async {
  final logRepo = ref.watch(exerciseLogRepositoryProvider);
  final allLogs = await logRepo.getActive();
  final exerciseLogIds = (allLogs.data ?? [])
      .where((log) => log.exerciseId == exerciseId)
      .map((log) => log.id)
      .toList();
  if (exerciseLogIds.isEmpty) {
    return null;
  }
  final setRepo = ref.watch(exerciseSetLogRepositoryProvider);
  final result = await setRepo.getByExerciseLogs(exerciseLogIds);
  final weights = (result.data ?? []).map((set) => set.weightKg).whereType<double>();
  if (weights.isEmpty) {
    return null;
  }
  return weights.reduce((a, b) => a > b ? a : b);
});

// Body Measurement Providers
final bodyMeasurementsInRangeProvider =
    FutureProvider.family<List<BodyMeasurement>, DateRangeQuery>((ref, range) async {
  final repo = ref.watch(bodyMeasurementRepositoryProvider);
  final result = await repo.getByDateRange(range.start, range.end);
  return result.data ?? [];
});
