import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/goal.dart';
import '../../../data/repositories/planning/goal_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class GoalService extends BaseServiceImpl<Goal> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';
  static const String progressField = 'progress';
  static const String parentGoalIdField = 'parentGoalId';
  static const double _minProgress = 0;
  static const double _maxProgress = 1;

  GoalService(GoalRepository super.repository, super.logger);

  GoalRepository get _repo => repository as GoalRepository;

  @override
  String get serviceName => 'GoalService';

  @override
  String get version => '1.0.0';

  @override
  Goal fromJson(Map<String, dynamic> json) => Goal.fromJson(json);

  @override
  Result<void, AppError> validate(Goal entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
        MapEntry(
          progressField,
          ValidationUtils.numericRange(
            value: entity.progress,
            fieldName: progressField,
            min: _minProgress,
            max: _maxProgress,
          ),
        ),
        MapEntry(
          parentGoalIdField,
          ValidationUtils.selfReference(
            id: entity.id,
            referenceId: entity.parentGoalId,
            fieldName: parentGoalIdField,
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
    final goals = active.data!;
    return Success(<String, dynamic>{
      'totalGoals': goals.length,
      'achievedGoals': goals.where((goal) => goal.status == GoalStatus.achieved).length,
    });
  }

  Future<Result<List<Goal>, AppError>> getByScope(GoalScope scope) {
    return _repo.getByScope(scope);
  }

  Future<Result<List<Goal>, AppError>> getChildren(String parentGoalId) {
    return _repo.getChildren(parentGoalId);
  }

  Future<Result<List<Goal>, AppError>> getDueOn(DateTime date) {
    return _repo.getDueOn(date);
  }
}
