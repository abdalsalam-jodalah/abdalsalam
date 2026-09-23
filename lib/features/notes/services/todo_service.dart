import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/notes/todo.dart';
import '../../../data/repositories/notes/todo_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class TodoService extends BaseServiceImpl<Todo> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';
  static const String orderField = 'order';
  static const String parentTodoIdField = 'parentTodoId';
  static const int _minOrder = 0;

  TodoService(TodoRepository super.repository, super.logger);

  TodoRepository get _repo => repository as TodoRepository;

  @override
  String get serviceName => 'TodoService';

  @override
  String get version => '1.0.0';

  @override
  Todo fromJson(Map<String, dynamic> json) => Todo.fromJson(json);

  @override
  Result<void, AppError> validate(Todo entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
        MapEntry(
          orderField,
          ValidationUtils.numericRange(value: entity.order, fieldName: orderField, min: _minOrder),
        ),
        MapEntry(
          parentTodoIdField,
          ValidationUtils.selfReference(
            id: entity.id,
            referenceId: entity.parentTodoId,
            fieldName: parentTodoIdField,
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
      'totalTodos': active.data!.length,
      'doneTodos': active.data!.where((todo) => todo.status == TodoStatus.done).length,
    });
  }

  Future<Result<List<Todo>, AppError>> byStatus(TodoStatus status) {
    return _repo.byStatus(status);
  }
}
