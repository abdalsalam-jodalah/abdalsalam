import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/planning_task.dart';
import '../../../data/repositories/planning/planning_task_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class PlanningTaskService extends BaseServiceImpl<PlanningTask> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';
  static const String orderField = 'order';
  static const String categoryIdsField = 'categoryIds';
  static const int _minOrder = 0;

  PlanningTaskService(PlanningTaskRepository super.repository, super.logger);

  PlanningTaskRepository get _repo => repository as PlanningTaskRepository;

  @override
  String get serviceName => 'PlanningTaskService';

  @override
  String get version => '1.0.0';

  @override
  PlanningTask fromJson(Map<String, dynamic> json) => PlanningTask.fromJson(json);

  @override
  Result<void, AppError> validate(PlanningTask entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
        MapEntry(
          orderField,
          ValidationUtils.numericRange(value: entity.order, fieldName: orderField, min: _minOrder),
        ),
        MapEntry(
          categoryIdsField,
          entity.categoryIds.toSet().length == entity.categoryIds.length
              ? null
              : '$categoryIdsField must not contain duplicates',
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
      'totalTasks': active.data!.length,
      'completedTasks': active.data!.where((task) => task.isCompleted).length,
    });
  }

  Future<Result<List<PlanningTask>, AppError>> getByDate(DateTime date) {
    return _repo.getByDate(date);
  }

  Future<Result<List<PlanningTask>, AppError>> getBoardTasks() {
    return _repo.getBoardTasks();
  }

  Future<Result<List<PlanningTask>, AppError>> getByGoal(String goalId) {
    return _repo.getByGoal(goalId);
  }
}
