import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise.dart';
import '../../../data/repositories/sports/exercise_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class ExerciseService extends BaseServiceImpl<Exercise> {
  static const String userIdField = 'userId';
  static const String nameField = 'name';
  static const String categoryIdField = 'categoryId';
  static const String defaultSetsField = 'defaultSets';
  static const String defaultRepsField = 'defaultReps';
  static const String defaultWeightKgField = 'defaultWeightKg';
  static const String orderField = 'order';
  static const int _minOrder = 0;
  static const double _minWeightKg = 0;

  ExerciseService(ExerciseRepository super.repository, super.logger);

  ExerciseRepository get _repo => repository as ExerciseRepository;

  @override
  String get serviceName => 'ExerciseService';

  @override
  String get version => '1.0.0';

  @override
  Exercise fromJson(Map<String, dynamic> json) => Exercise.fromJson(json);

  @override
  Result<void, AppError> validate(Exercise entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(nameField, ValidationUtils.requiredField(entity.name, nameField)),
        MapEntry(categoryIdField, ValidationUtils.requiredField(entity.categoryId, categoryIdField)),
        MapEntry(
          defaultSetsField,
          ValidationUtils.positiveNumber(value: entity.defaultSets, fieldName: defaultSetsField),
        ),
        MapEntry(
          defaultRepsField,
          ValidationUtils.positiveNumber(value: entity.defaultReps, fieldName: defaultRepsField),
        ),
        MapEntry(
          defaultWeightKgField,
          ValidationUtils.numericRange(
            value: entity.defaultWeightKg,
            fieldName: defaultWeightKgField,
            min: _minWeightKg,
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
      'totalExercises': active.data!.length,
    });
  }

  Future<Result<List<Exercise>, AppError>> getByCategory(String categoryId) {
    return _repo.getByCategory(categoryId);
  }
}
