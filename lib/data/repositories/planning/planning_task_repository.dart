import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/planning_task.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class PlanningTaskRepository extends BaseRepository<PlanningTask> {
  Future<Result<List<PlanningTask>, AppError>> getByDate(DateTime date);
  Future<Result<List<PlanningTask>, AppError>> getByGoal(String goalId);
}

class PlanningTaskRepositoryImpl extends BaseRepositoryImpl<PlanningTask>
    implements PlanningTaskRepository {
  PlanningTaskRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_planning_tasks';

  @override
  PlanningTask fromJson(Map<String, dynamic> json) => PlanningTask.fromJson(json);

  @override
  Future<Result<List<PlanningTask>, AppError>> getByDate(DateTime date) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }

    final matches = result.data!
        .where((task) =>
            task.date != null &&
            task.date!.year == date.year &&
            task.date!.month == date.month &&
            task.date!.day == date.day)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Success(matches);
  }

  @override
  Future<Result<List<PlanningTask>, AppError>> getByGoal(String goalId) async {
    final result = await query(<String, dynamic>{'goalId': goalId});
    if (result.isFailure) {
      return result;
    }

    final sorted = [...result.data!]..sort((a, b) => a.order.compareTo(b.order));
    return Success(sorted);
  }
}
