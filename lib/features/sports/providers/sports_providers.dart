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
import '../services/body_measurement_service.dart';
import '../services/exercise_category_service.dart';
import '../services/exercise_log_service.dart';
import '../services/exercise_service.dart';
import '../services/exercise_set_log_service.dart';
import '../services/weekly_schedule_service.dart';

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

final exerciseCategoryServiceProvider = Provider<ExerciseCategoryService>((ref) {
  return ExerciseCategoryService(
    ref.watch(exerciseCategoryRepositoryProvider),
    LoggerService.forModule('ExerciseCategoryService', moduleType: logic.ModuleType.service),
  );
});

final exerciseServiceProvider = Provider<ExerciseService>((ref) {
  return ExerciseService(
    ref.watch(exerciseRepositoryProvider),
    LoggerService.forModule('ExerciseService', moduleType: logic.ModuleType.service),
  );
});

final weeklyScheduleServiceProvider = Provider<WeeklyScheduleService>((ref) {
  return WeeklyScheduleService(
    ref.watch(weeklyScheduleRepositoryProvider),
    LoggerService.forModule('WeeklyScheduleService', moduleType: logic.ModuleType.service),
  );
});

final exerciseLogServiceProvider = Provider<ExerciseLogService>((ref) {
  return ExerciseLogService(
    ref.watch(exerciseLogRepositoryProvider),
    LoggerService.forModule('ExerciseLogService', moduleType: logic.ModuleType.service),
  );
});

final exerciseSetLogServiceProvider = Provider<ExerciseSetLogService>((ref) {
  return ExerciseSetLogService(
    ref.watch(exerciseSetLogRepositoryProvider),
    LoggerService.forModule('ExerciseSetLogService', moduleType: logic.ModuleType.service),
  );
});

final bodyMeasurementServiceProvider = Provider<BodyMeasurementService>((ref) {
  return BodyMeasurementService(
    ref.watch(bodyMeasurementRepositoryProvider),
    LoggerService.forModule('BodyMeasurementService', moduleType: logic.ModuleType.service),
  );
});

// Catalog Providers
final exerciseCategoriesProvider = FutureProvider<List<ExerciseCategory>>((ref) async {
  final service = ref.watch(exerciseCategoryServiceProvider);
  final result = await service.getAllOrdered();
  return result.getOrThrow();
});

final exercisesByCategoryProvider =
    FutureProvider.autoDispose.family<List<Exercise>, String>((ref, categoryId) async {
  final service = ref.watch(exerciseServiceProvider);
  final result = await service.getByCategory(categoryId);
  return result.getOrThrow();
});

final allActiveExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final service = ref.watch(exerciseServiceProvider);
  final result = await service.getActive();
  return result.getOrThrow();
});

// Weekly Schedule Providers
final scheduleForDayProvider =
    FutureProvider.autoDispose.family<List<WeeklyScheduleEntry>, int>((ref, dayOfWeek) async {
  final service = ref.watch(weeklyScheduleServiceProvider);
  final result = await service.getByDayOfWeek(dayOfWeek);
  return result.getOrThrow();
});

final fullWeekScheduleProvider = FutureProvider<List<WeeklyScheduleEntry>>((ref) async {
  final service = ref.watch(weeklyScheduleServiceProvider);
  final result = await service.getFullWeek();
  return result.getOrThrow();
});

// Daily Log Providers
final logsForDateProvider =
    FutureProvider.autoDispose.family<List<ExerciseLog>, DateTime>((ref, date) async {
  final service = ref.watch(exerciseLogServiceProvider);
  final result = await service.getByDate(dateOnly(date));
  return result.getOrThrow();
});

final setsForLogProvider =
    FutureProvider.autoDispose.family<List<ExerciseSetLog>, String>((ref, logId) async {
  final service = ref.watch(exerciseSetLogServiceProvider);
  final result = await service.getByExerciseLog(logId);
  return result.getOrThrow();
});

typedef DateRangeQuery = ({DateTime start, DateTime end});

final logsInRangeProvider =
    FutureProvider.autoDispose.family<List<ExerciseLog>, DateRangeQuery>((ref, range) async {
  final service = ref.watch(exerciseLogServiceProvider);
  final result = await service.getByDateRange(range.start, range.end);
  return result.getOrThrow();
});

typedef ExerciseRangeQuery = ({String exerciseId, DateTime start, DateTime end});

final logsForExerciseInRangeProvider =
    FutureProvider.autoDispose.family<List<ExerciseLog>, ExerciseRangeQuery>((ref, query) async {
  final logs = await ref.watch(
    logsInRangeProvider((start: query.start, end: query.end)).future,
  );
  return logs.where((log) => log.exerciseId == query.exerciseId).toList(growable: false);
});

final setsForExerciseInRangeProvider =
    FutureProvider.autoDispose.family<List<ExerciseSetLog>, ExerciseRangeQuery>((ref, query) async {
  final logs = await ref.watch(logsForExerciseInRangeProvider(query).future);
  if (logs.isEmpty) {
    return const [];
  }
  final service = ref.watch(exerciseSetLogServiceProvider);
  final result = await service.getByExerciseLogs(logs.map((log) => log.id).toList());
  return result.getOrThrow();
});

/// Best all-time [ExerciseSetLog.weightKg] for a strength exercise, used to
/// flag personal records while logging.
final personalRecordProvider =
    FutureProvider.autoDispose.family<double?, String>((ref, exerciseId) async {
  final logService = ref.watch(exerciseLogServiceProvider);
  final allLogs = await logService.getActive();
  final exerciseLogIds = allLogs
      .getOrThrow()
      .where((log) => log.exerciseId == exerciseId)
      .map((log) => log.id)
      .toList();
  if (exerciseLogIds.isEmpty) {
    return null;
  }
  final setService = ref.watch(exerciseSetLogServiceProvider);
  final result = await setService.getByExerciseLogs(exerciseLogIds);
  final weights = result.getOrThrow().map((set) => set.weightKg).whereType<double>();
  if (weights.isEmpty) {
    return null;
  }
  return weights.reduce((a, b) => a > b ? a : b);
});

// Body Measurement Providers
final bodyMeasurementsInRangeProvider =
    FutureProvider.autoDispose.family<List<BodyMeasurement>, DateRangeQuery>((ref, range) async {
  final service = ref.watch(bodyMeasurementServiceProvider);
  final result = await service.getByDateRange(range.start, range.end);
  return result.getOrThrow();
});
