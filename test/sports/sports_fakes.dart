import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/models/sports/body_measurement.dart';
import 'package:abdalsalam/data/models/sports/exercise.dart';
import 'package:abdalsalam/data/models/sports/exercise_category.dart';
import 'package:abdalsalam/data/models/sports/exercise_log.dart';
import 'package:abdalsalam/data/models/sports/exercise_set_log.dart';
import 'package:abdalsalam/data/models/sports/weekly_schedule_entry.dart';
import 'package:abdalsalam/data/repositories/sports/body_measurement_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_category_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_log_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_repository.dart';
import 'package:abdalsalam/data/repositories/sports/exercise_set_log_repository.dart';
import 'package:abdalsalam/data/repositories/sports/weekly_schedule_repository.dart';

AppError fakeSportsStorageFailure() => DatabaseError('fake sports storage failure');

class FakeSportsCrudRepository<T extends BaseModel> {
  final List<T> items;
  bool shouldFailGetActive = false;
  bool shouldFailGetByDateRange = false;

  FakeSportsCrudRepository([List<T>? seed]) : items = seed ?? <T>[];

  Future<Result<List<T>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  Future<Result<List<T>, AppError>> getByDateRange(DateTime start, DateTime end) async {
    if (shouldFailGetByDateRange) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeExerciseCategoryRepository extends FakeSportsCrudRepository<ExerciseCategory>
    implements ExerciseCategoryRepository {
  bool shouldFailGetAllOrdered = false;

  FakeExerciseCategoryRepository([super.seed]);

  @override
  Future<Result<List<ExerciseCategory>, AppError>> getAllOrdered() async {
    if (shouldFailGetAllOrdered) {
      return Failure(fakeSportsStorageFailure());
    }
    final ordered = List<ExerciseCategory>.of(items)..sort((a, b) => a.order.compareTo(b.order));
    return Success(ordered);
  }
}

class FakeExerciseRepository extends FakeSportsCrudRepository<Exercise> implements ExerciseRepository {
  bool shouldFailGetByCategory = false;

  FakeExerciseRepository([super.seed]);

  @override
  Future<Result<List<Exercise>, AppError>> getByCategory(String categoryId) async {
    if (shouldFailGetByCategory) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(items.where((exercise) => exercise.categoryId == categoryId).toList());
  }
}

class FakeWeeklyScheduleRepository extends FakeSportsCrudRepository<WeeklyScheduleEntry>
    implements WeeklyScheduleRepository {
  bool shouldFailGetByDayOfWeek = false;
  bool shouldFailGetFullWeek = false;

  FakeWeeklyScheduleRepository([super.seed]);

  @override
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getByDayOfWeek(int dayOfWeek) async {
    if (shouldFailGetByDayOfWeek) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(items.where((entry) => entry.dayOfWeek == dayOfWeek).toList());
  }

  @override
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getFullWeek() async {
    if (shouldFailGetFullWeek) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(List<WeeklyScheduleEntry>.of(items));
  }
}

class FakeExerciseLogRepository extends FakeSportsCrudRepository<ExerciseLog> implements ExerciseLogRepository {
  bool shouldFailGetByDate = false;

  FakeExerciseLogRepository([super.seed]);

  @override
  Future<Result<List<ExerciseLog>, AppError>> getByDate(DateTime date) async {
    if (shouldFailGetByDate) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(items
        .where((log) => log.date.year == date.year && log.date.month == date.month && log.date.day == date.day)
        .toList());
  }
}

class FakeExerciseSetLogRepository extends FakeSportsCrudRepository<ExerciseSetLog>
    implements ExerciseSetLogRepository {
  bool shouldFailGetByExerciseLog = false;
  bool shouldFailGetByExerciseLogs = false;

  FakeExerciseSetLogRepository([super.seed]);

  @override
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLog(String exerciseLogId) async {
    if (shouldFailGetByExerciseLog) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(items.where((set) => set.exerciseLogId == exerciseLogId).toList());
  }

  @override
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLogs(List<String> exerciseLogIds) async {
    if (shouldFailGetByExerciseLogs) {
      return Failure(fakeSportsStorageFailure());
    }
    return Success(items.where((set) => exerciseLogIds.contains(set.exerciseLogId)).toList());
  }
}

class FakeBodyMeasurementRepository extends FakeSportsCrudRepository<BodyMeasurement>
    implements BodyMeasurementRepository {
  FakeBodyMeasurementRepository([super.seed]);
}

ExerciseCategory buildExerciseCategory({
  String id = 'category-1',
  String userId = 'user1',
  String name = 'Chest',
  int order = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return ExerciseCategory(id: id, createdAt: now, updatedAt: now, userId: userId, name: name, order: order);
}

Exercise buildExercise({
  String id = 'exercise-1',
  String userId = 'user1',
  String name = 'Bench press',
  String categoryId = 'category-1',
}) {
  final now = DateTime(2026, 1, 1);
  return Exercise(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    name: name,
    categoryId: categoryId,
    trackingType: ExerciseTrackingType.reps,
  );
}

WeeklyScheduleEntry buildWeeklyScheduleEntry({
  String id = 'schedule-1',
  String userId = 'user1',
  int dayOfWeek = DateTime.monday,
  String exerciseId = 'exercise-1',
}) {
  final now = DateTime(2026, 1, 1);
  return WeeklyScheduleEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    dayOfWeek: dayOfWeek,
    exerciseId: exerciseId,
  );
}

ExerciseLog buildExerciseLog({
  String id = 'log-1',
  String userId = 'user1',
  DateTime? date,
  String exerciseId = 'exercise-1',
}) {
  final resolvedDate = date ?? DateTime(2026, 1, 1);
  return ExerciseLog(
    id: id,
    createdAt: resolvedDate,
    updatedAt: resolvedDate,
    userId: userId,
    date: resolvedDate,
    exerciseId: exerciseId,
  );
}

ExerciseSetLog buildExerciseSetLog({
  String id = 'set-1',
  String userId = 'user1',
  String exerciseLogId = 'log-1',
  int setNumber = 1,
  int reps = 10,
  double? weightKg,
}) {
  final now = DateTime(2026, 1, 1);
  return ExerciseSetLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    exerciseLogId: exerciseLogId,
    setNumber: setNumber,
    reps: reps,
    weightKg: weightKg,
  );
}

BodyMeasurement buildBodyMeasurement({
  String id = 'measurement-1',
  String userId = 'user1',
  DateTime? date,
  double weightKg = 80,
}) {
  final resolvedDate = date ?? DateTime(2026, 1, 1);
  return BodyMeasurement(
    id: id,
    createdAt: resolvedDate,
    updatedAt: resolvedDate,
    userId: userId,
    date: resolvedDate,
    weightKg: weightKg,
  );
}
