import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/exercise_set_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class ExerciseSetLogRepository extends BaseRepository<ExerciseSetLog> {
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLog(String exerciseLogId);
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLogs(List<String> exerciseLogIds);
}

class ExerciseSetLogRepositoryImpl extends BaseRepositoryImpl<ExerciseSetLog>
    implements ExerciseSetLogRepository {
  ExerciseSetLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_exercise_set_logs';

  @override
  ExerciseSetLog fromJson(Map<String, dynamic> json) => ExerciseSetLog.fromJson(json);

  @override
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLog(String exerciseLogId) async {
    final result = await query(<String, dynamic>{'exerciseLogId': exerciseLogId});
    if (result.isFailure) {
      return result;
    }
    final sorted = [...result.data!]..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return Success(sorted);
  }

  @override
  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLogs(
    List<String> exerciseLogIds,
  ) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final idSet = exerciseLogIds.toSet();
    final matches = result.data!.where((set) => idSet.contains(set.exerciseLogId)).toList()
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return Success(matches);
  }
}
