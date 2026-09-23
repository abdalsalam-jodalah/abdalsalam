import 'package:abdalsalam/data/models/notes/todo.dart';
import 'package:abdalsalam/data/repositories/notes/todo_repository.dart';
import 'package:abdalsalam/features/notes/services/todo_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingTodoRepository = TodoRepositoryImpl with FailingWrites<Todo>;

Todo _todo({
  String userId = 'u1',
  String title = 'Call the bank',
  TodoStatus status = TodoStatus.pending,
  int order = 0,
  String? parentTodoId,
}) {
  final now = DateTime(2026, 1, 1);
  return Todo(
    id: 'todo-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    description: null,
    dueDate: null,
    priority: TodoPriority.medium,
    status: status,
    categoryId: null,
    tags: const [],
    reminderAt: null,
    parentTodoId: parentTodoId,
    order: order,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late TodoService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_todo_service_test.db', tables: ['todos']);
    logger = LoggerService.forModule('TodoServiceTest');
    service = TodoService(TodoRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('TodoService.validate', () {
    test('should succeed for a well-formed todo', () {
      expect(service.validate(_todo()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_todo(userId: '')), TodoService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_todo(title: '')), TodoService.titleField);
    });

    test('should report order when order is negative', () {
      expectFieldError(service.validate(_todo(order: -1)), TodoService.orderField);
    });

    test('should report parentTodoId when a todo is its own parent', () {
      expectFieldError(service.validate(_todo(parentTodoId: 'todo-1')), TodoService.parentTodoIdField);
    });
  });

  group('TodoService writes', () {
    test('should persist a created todo', () async {
      final result = await service.create(_todo());

      expect(result.isSuccess, isTrue);
      final stored = await service.byStatus(TodoStatus.pending);
      expect(stored.data?.map((todo) => todo.id), ['todo-1']);
    });

    test('should persist a completed toggle', () async {
      await service.create(_todo());

      final result = await service.update(_todo(status: TodoStatus.done));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('todo-1');
      expect(stored.data?.status, TodoStatus.done);
    });

    test('should propagate a repository create failure', () async {
      final failingService = TodoService(_FailingTodoRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_todo()));
    });

    test('should propagate a repository update failure', () async {
      final failingService = TodoService(_FailingTodoRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_todo()));
    });
  });
}
