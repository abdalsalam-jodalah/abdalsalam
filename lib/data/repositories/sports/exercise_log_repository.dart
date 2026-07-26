import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/exercise_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class ExerciseLogRepository extends BaseRepository<ExerciseLog> {
  Future<Result<List<ExerciseLog>, AppError>> getByDate(DateTime date);
}

class ExerciseLogRepositoryImpl extends BaseRepositoryImpl<ExerciseLog>
    implements ExerciseLogRepository {
  ExerciseLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_exercise_logs';

  @override
  ExerciseLog fromJson(Map<String, dynamic> json) => ExerciseLog.fromJson(json);

  @override
  Future<Result<List<ExerciseLog>, AppError>> getByDate(DateTime date) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final matches = result.data!
        .where((log) =>
            log.date.year == date.year && log.date.month == date.month && log.date.day == date.day)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Success(matches);
  }

  /// Overridden to filter on the logical [ExerciseLog.date] (the day the
  /// exercise was actually performed, which can be back-logged) rather than
  /// [ExerciseLog.createdAt] like the base implementation.
  @override
  Future<Result<List<ExerciseLog>, AppError>> getByDateRange(DateTime start, DateTime end) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final matches = result.data!
        .where((log) => !log.date.isBefore(start) && !log.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return Success(matches);
  }
}
