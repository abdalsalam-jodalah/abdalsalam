import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/goal.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class GoalRepository extends BaseRepository<Goal> {
  Future<Result<List<Goal>, AppError>> getByScope(GoalScope scope);
  Future<Result<List<Goal>, AppError>> getChildren(String parentGoalId);
  Future<Result<List<Goal>, AppError>> getDueOn(DateTime date);
}

class GoalRepositoryImpl extends BaseRepositoryImpl<Goal>
    implements GoalRepository {
  GoalRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_goals';

  @override
  Goal fromJson(Map<String, dynamic> json) => Goal.fromJson(json);

  @override
  Future<Result<List<Goal>, AppError>> getByScope(GoalScope scope) {
    return query(<String, dynamic>{'scope': scope.name});
  }

  @override
  Future<Result<List<Goal>, AppError>> getChildren(String parentGoalId) {
    return query(<String, dynamic>{'parentGoalId': parentGoalId});
  }

  @override
  Future<Result<List<Goal>, AppError>> getDueOn(DateTime date) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }

    final matches = result.data!
        .where((goal) =>
            goal.targetDate != null &&
            goal.targetDate!.year == date.year &&
            goal.targetDate!.month == date.month &&
            goal.targetDate!.day == date.day)
        .toList(growable: false);

    return Success(matches);
  }
}
