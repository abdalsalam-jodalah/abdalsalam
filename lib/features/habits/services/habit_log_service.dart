import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/habits/habit_log.dart';
import '../../../data/repositories/habits/habit_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class HabitLogService extends BaseServiceImpl<HabitLog> {
  static const String userIdField = 'userId';
  static const String habitIdField = 'habitId';
  static const String intensityField = 'intensity';
  static const int _minIntensity = 1;
  static const int _maxIntensity = 5;

  HabitLogService(HabitLogRepository super.repository, super.logger);

  HabitLogRepository get _repo => repository as HabitLogRepository;

  @override
  String get serviceName => 'HabitLogService';

  @override
  String get version => '1.0.0';

  @override
  HabitLog fromJson(Map<String, dynamic> json) => HabitLog.fromJson(json);

  @override
  Result<void, AppError> validate(HabitLog entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(habitIdField, ValidationUtils.requiredField(entity.habitId, habitIdField)),
        MapEntry(
          intensityField,
          ValidationUtils.numericRange(
            value: entity.intensity,
            fieldName: intensityField,
            min: _minIntensity,
            max: _maxIntensity,
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

  Future<Result<List<HabitLog>, AppError>> getByHabit(String habitId) {
    return _repo.getByHabit(habitId);
  }

  Future<Result<List<HabitLog>, AppError>> getByHabitAndDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) {
    return _repo.getByHabitAndDateRange(habitId, start, end);
  }
}
