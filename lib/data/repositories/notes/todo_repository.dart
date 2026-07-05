import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/notes/todo.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class TodoRepository extends BaseRepository<Todo> {
  Future<Result<List<Todo>, AppError>> byStatus(TodoStatus status);
}

class TodoRepositoryImpl extends BaseRepositoryImpl<Todo>
    implements TodoRepository {
  TodoRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'todos';

  @override
  Todo fromJson(Map<String, dynamic> json) => Todo.fromJson(json);

  @override
  Future<Result<List<Todo>, AppError>> byStatus(TodoStatus status) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final result = all.data!
        .where((item) => item.status == status)
        .toList(growable: false);

    return Success(result);
  }
}
