import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/models/notes/note.dart';
import 'package:abdalsalam/data/models/notes/todo.dart';
import 'package:abdalsalam/data/repositories/notes/notes_repository.dart';
import 'package:abdalsalam/data/repositories/notes/todo_repository.dart';

AppError fakeNotesStorageFailure() => DatabaseError('fake notes storage failure');

class FakeNotesCrudRepository<T extends BaseModel> {
  final List<T> items;
  bool shouldFailGetActive = false;
  bool shouldFailQuery = false;
  int getActiveCallCount = 0;

  FakeNotesCrudRepository([List<T>? seed]) : items = seed ?? <T>[];

  Future<Result<List<T>, AppError>> getActive() async {
    getActiveCallCount++;
    if (shouldFailGetActive) {
      return Failure(fakeNotesStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  Future<Result<List<T>, AppError>> query(Map<String, dynamic> filters) async {
    if (shouldFailQuery) {
      return Failure(fakeNotesStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeNotesRepository extends FakeNotesCrudRepository<Note> implements NotesRepository {
  FakeNotesRepository([super.seed]);
}

class FakeTodoRepository extends FakeNotesCrudRepository<Todo> implements TodoRepository {
  FakeTodoRepository([super.seed]);

  @override
  Future<Result<List<Todo>, AppError>> query(Map<String, dynamic> filters) async {
    if (shouldFailQuery) {
      return Failure(fakeNotesStorageFailure());
    }
    final habitId = filters['habitId'];
    return Success(items.where((todo) => todo.habitId == habitId).toList());
  }
}

Note buildNote({
  String id = 'note-1',
  String userId = 'user1',
  String title = 'Title',
  int order = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    content: 'Content',
    tags: const <String>[],
    categoryId: null,
    pinned: false,
    archived: false,
    attachments: const <String>[],
    color: null,
    order: order,
  );
}

Todo buildTodo({
  String id = 'todo-1',
  String userId = 'user1',
  String title = 'Title',
  int order = 0,
  String? habitId,
}) {
  final now = DateTime(2026, 1, 1);
  return Todo(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    description: '',
    dueDate: null,
    priority: TodoPriority.medium,
    status: TodoStatus.pending,
    categoryId: null,
    tags: const <String>[],
    reminderAt: null,
    parentTodoId: null,
    order: order,
    habitId: habitId,
  );
}
