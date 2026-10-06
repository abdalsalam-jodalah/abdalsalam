import '../../models/planning/task_category.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class TaskCategoryRepository extends BaseRepository<TaskCategory> {}

class TaskCategoryRepositoryImpl extends BaseRepositoryImpl<TaskCategory> implements TaskCategoryRepository {
  TaskCategoryRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'planning_task_categories';

  @override
  TaskCategory fromJson(Map<String, dynamic> json) => TaskCategory.fromJson(json);
}
