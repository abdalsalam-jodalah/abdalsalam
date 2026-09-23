import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise_log.dart';
import '../../../data/repositories/sports/exercise_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class ExerciseLogService extends BaseServiceImpl<ExerciseLog> {
  static const String userIdField = 'userId';
  static const String exerciseIdField = 'exerciseId';
  static const String orderField = 'order';
  static const String stepsField = 'steps';
  static const String durationSecondsField = 'durationSeconds';
  static const String distanceKmField = 'distanceKm';
  static const int _minOrder = 0;
  static const int _minSteps = 0;
  static const int _minDurationSeconds = 0;
  static const double _minDistanceKm = 0;

  ExerciseLogService(ExerciseLogRepository super.repository, super.logger);

  ExerciseLogRepository get _repo => repository as ExerciseLogRepository;

  @override
  String get serviceName => 'ExerciseLogService';

  @override
  String get version => '1.0.0';

  @override
  ExerciseLog fromJson(Map<String, dynamic> json) => ExerciseLog.fromJson(json);

  @override
  Result<void, AppError> validate(ExerciseLog entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(exerciseIdField, ValidationUtils.requiredField(entity.exerciseId, exerciseIdField)),
        MapEntry(
          orderField,
          ValidationUtils.numericRange(value: entity.order, fieldName: orderField, min: _minOrder),
        ),
        MapEntry(
          stepsField,
          ValidationUtils.numericRange(value: entity.steps, fieldName: stepsField, min: _minSteps),
        ),
        MapEntry(
          durationSecondsField,
          ValidationUtils.numericRange(
            value: entity.durationSeconds,
            fieldName: durationSecondsField,
            min: _minDurationSeconds,
          ),
        ),
        MapEntry(
          distanceKmField,
          ValidationUtils.numericRange(
            value: entity.distanceKm,
            fieldName: distanceKmField,
            min: _minDistanceKm,
          ),
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
      'totalLogs': active.data!.length,
    });
  }

  Future<Result<List<ExerciseLog>, AppError>> getByDate(DateTime date) {
    return _repo.getByDate(date);
  }
}
