import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/weekly_schedule_entry.dart';
import '../../../data/repositories/sports/weekly_schedule_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class WeeklyScheduleService extends BaseServiceImpl<WeeklyScheduleEntry> {
  static const String userIdField = 'userId';
  static const String exerciseIdField = 'exerciseId';
  static const String dayOfWeekField = 'dayOfWeek';
  static const String orderField = 'order';
  static const int _minOrder = 0;

  WeeklyScheduleService(WeeklyScheduleRepository super.repository, super.logger);

  WeeklyScheduleRepository get _repo => repository as WeeklyScheduleRepository;

  @override
  String get serviceName => 'WeeklyScheduleService';

  @override
  String get version => '1.0.0';

  @override
  WeeklyScheduleEntry fromJson(Map<String, dynamic> json) => WeeklyScheduleEntry.fromJson(json);

  @override
  Result<void, AppError> validate(WeeklyScheduleEntry entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(exerciseIdField, ValidationUtils.requiredField(entity.exerciseId, exerciseIdField)),
        MapEntry(
          dayOfWeekField,
          ValidationUtils.numericRange(
            value: entity.dayOfWeek,
            fieldName: dayOfWeekField,
            min: DateTime.monday,
            max: DateTime.sunday,
          ),
        ),
        MapEntry(
          orderField,
          ValidationUtils.numericRange(value: entity.order, fieldName: orderField, min: _minOrder),
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
      'totalEntries': active.data!.length,
      'enabledEntries': active.data!.where((entry) => entry.enabled).length,
    });
  }

  Future<Result<List<WeeklyScheduleEntry>, AppError>> getByDayOfWeek(int dayOfWeek) {
    return _repo.getByDayOfWeek(dayOfWeek);
  }

  Future<Result<List<WeeklyScheduleEntry>, AppError>> getFullWeek() {
    return _repo.getFullWeek();
  }
}
