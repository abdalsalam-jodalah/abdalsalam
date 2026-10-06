import '../../../core/errors/app_error.dart';
import '../../../core/formatting/hex_color.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/task_category.dart';
import '../../../data/repositories/planning/planning_task_repository.dart';
import '../../../data/repositories/planning/task_category_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class TaskCategoryService extends BaseServiceImpl<TaskCategory> {
  static const String userIdField = 'userId';
  static const String nameField = 'name';
  static const String colorField = 'color';
  static const int maxNameLength = 30;

  final PlanningTaskRepository _taskRepository;

  TaskCategoryService(
    TaskCategoryRepository super.repository,
    super.logger, {
    required PlanningTaskRepository taskRepository,
  }) : _taskRepository = taskRepository;

  @override
  String get serviceName => 'TaskCategoryService';

  @override
  String get version => '1.0.0';

  @override
  TaskCategory fromJson(Map<String, dynamic> json) => TaskCategory.fromJson(json);

  @override
  Result<void, AppError> validate(TaskCategory entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(nameField, ValidationUtils.requiredField(entity.name, nameField) ?? _validateNameLength(entity.name)),
        MapEntry(
          colorField,
          HexColor.isValid(entity.color) ? null : '$colorField must be a hex color like #RRGGBB',
        ),
      ]),
    );
  }

  @override
  Future<Result<TaskCategory, AppError>> create(TaskCategory entity) async {
    final duplicate = await _checkNameAvailable(entity);
    if (duplicate != null) {
      return Failure(duplicate);
    }
    return super.create(entity);
  }

  @override
  Future<Result<void, AppError>> update(TaskCategory entity) async {
    final duplicate = await _checkNameAvailable(entity);
    if (duplicate != null) {
      return Failure(duplicate);
    }
    return super.update(entity);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    return Success(<String, dynamic>{'totalCategories': active.data!.length});
  }

  Future<Result<List<TaskCategory>, AppError>> getActiveSortedByName() async {
    final active = await getActive();
    if (active.isFailure) {
      return active;
    }
    final sorted = [...active.data!]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Success(sorted);
  }

  Future<Result<void, AppError>> deleteAndDetach(String categoryId) async {
    final tasks = await _taskRepository.getByCategory(categoryId);
    if (tasks.isFailure) {
      return Failure(tasks.error!);
    }
    final deletion = await softDelete(categoryId);
    if (deletion.isFailure) {
      return deletion;
    }
    final now = DateTime.now();
    final detached = tasks.data!
        .where((task) => task.deletedAt == null)
        .map(
          (task) => task.copyWith(
            categoryIds: task.categoryIds.where((id) => id != categoryId).toList(growable: false),
            updatedAt: now,
          ),
        )
        .toList(growable: false);
    if (detached.isEmpty) {
      return const Success(null);
    }
    final detachment = await _taskRepository.updateBulk(detached);
    if (detachment.isFailure) {
      logger.warning(
        '[$serviceName] category $categoryId deleted but ${detached.length} tasks still reference it: ${detachment.error}',
      );
    }
    return detachment;
  }

  String? _validateNameLength(String name) {
    return name.trim().length > maxNameLength ? '$nameField must be at most $maxNameLength characters' : null;
  }

  Future<AppError?> _checkNameAvailable(TaskCategory entity) async {
    final wanted = entity.name.trim().toLowerCase();
    if (wanted.isEmpty) {
      return null;
    }
    final active = await getActive();
    if (active.isFailure) {
      return active.error;
    }
    final isTaken = active.data!.any((other) => other.id != entity.id && other.name.trim().toLowerCase() == wanted);
    if (!isTaken) {
      return null;
    }
    return ValidationError(
      'A category named "${entity.name.trim()}" already exists',
      fieldErrors: <String, String>{nameField: 'Already exists'},
    );
  }
}
