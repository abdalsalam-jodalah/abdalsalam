import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/sports/exercise_category.dart';
import '../../../data/repositories/sports/exercise_category_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class ExerciseCategoryService extends BaseServiceImpl<ExerciseCategory> {
  static const String userIdField = 'userId';
  static const String nameField = 'name';
  static const String orderField = 'order';
  static const int _minOrder = 0;

  ExerciseCategoryService(ExerciseCategoryRepository super.repository, super.logger);

  ExerciseCategoryRepository get _repo => repository as ExerciseCategoryRepository;

  @override
  String get serviceName => 'ExerciseCategoryService';

  @override
  String get version => '1.0.0';

  @override
  ExerciseCategory fromJson(Map<String, dynamic> json) => ExerciseCategory.fromJson(json);

  @override
  Result<void, AppError> validate(ExerciseCategory entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(nameField, ValidationUtils.requiredField(entity.name, nameField)),
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
      'totalCategories': active.data!.length,
    });
  }

  Future<Result<List<ExerciseCategory>, AppError>> getAllOrdered() {
    return _repo.getAllOrdered();
  }
}
