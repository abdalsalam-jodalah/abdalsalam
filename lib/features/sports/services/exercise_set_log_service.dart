import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise_set_log.dart';
import '../../../data/repositories/sports/exercise_set_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class ExerciseSetLogService extends BaseServiceImpl<ExerciseSetLog> {
  static const String userIdField = 'userId';
  static const String exerciseLogIdField = 'exerciseLogId';
  static const String setNumberField = 'setNumber';
  static const String repsField = 'reps';
  static const String weightKgField = 'weightKg';
  static const double _minWeightKg = 0;

  ExerciseSetLogService(ExerciseSetLogRepository super.repository, super.logger);

  ExerciseSetLogRepository get _repo => repository as ExerciseSetLogRepository;

  @override
  String get serviceName => 'ExerciseSetLogService';

  @override
  String get version => '1.0.0';

  @override
  ExerciseSetLog fromJson(Map<String, dynamic> json) => ExerciseSetLog.fromJson(json);

  @override
  Result<void, AppError> validate(ExerciseSetLog entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(
          exerciseLogIdField,
          ValidationUtils.requiredField(entity.exerciseLogId, exerciseLogIdField),
        ),
        MapEntry(
          setNumberField,
          ValidationUtils.positiveNumber(value: entity.setNumber, fieldName: setNumberField),
        ),
        MapEntry(repsField, ValidationUtils.positiveNumber(value: entity.reps, fieldName: repsField)),
        MapEntry(
          weightKgField,
          ValidationUtils.numericRange(value: entity.weightKg, fieldName: weightKgField, min: _minWeightKg),
        ),
      ]),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    return Success(<String, dynamic>{
      'totalSets': active.data!.length,
      'totalReps': active.data!.fold<int>(0, (sum, set) => sum + set.reps),
    });
  }

  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLog(String exerciseLogId) {
    return _repo.getByExerciseLog(exerciseLogId);
  }

  Future<Result<List<ExerciseSetLog>, AppError>> getByExerciseLogs(List<String> exerciseLogIds) {
    return _repo.getByExerciseLogs(exerciseLogIds);
  }
}
