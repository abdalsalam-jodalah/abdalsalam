import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/notes/note.dart';
import 'package:abdalsalam/data/models/notes/todo.dart';
import 'package:abdalsalam/data/repositories/notes/notes_repository.dart';
import 'package:abdalsalam/features/notes/services/notes_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/throwing_reminder_service.dart';
import '../support/validation_expectations.dart';

class _FailingNotesRepository = NotesRepositoryImpl with FailingWrites<Note>;

Note _note({String id = 'note-1', String userId = 'u1', String title = 'Groceries', int order = 0}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: userId,
    title: title,
    content: 'Milk, eggs',
    tags: const [],
    categoryId: null,
    pinned: false,
    archived: false,
    attachments: const [],
    color: null,
    order: order,
  );
}

Todo _todo({DateTime? reminderAt}) {
  final now = DateTime(2026, 1, 1);
  return Todo(
    id: 'todo-1',
    createdAt: now,
    updatedAt: now,
    userId: 'u1',
    title: 'Call the bank',
    description: null,
    dueDate: null,
    priority: TodoPriority.medium,
    status: TodoStatus.pending,
    categoryId: null,
    tags: const [],
    reminderAt: reminderAt,
    parentTodoId: null,
    order: 0,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late NotesService service;

  setUp(() async {
    await resetTestStorage(databaseName: 'test_notes_service_test.db', tables: ['notes']);
    logger = LoggerService.forModule('NotesServiceTest');
    service = NotesService(
      NotesRepositoryImpl(StorageGateway.instance, logger),
      logger,
      reminders: ThrowingReminderService(logger),
    );
  });

  group('NotesService.validate', () {
    test('should succeed for a well-formed note', () {
      expect(service.validate(_note()).isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_note(userId: '')), NotesService.userIdField);
    });

    test('should report title when title is blank', () {
      expectFieldError(service.validate(_note(title: ' ')), NotesService.titleField);
    });
  });

  group('NotesService writes', () {
    test('should persist a created note', () async {
      final result = await service.create(_note());

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('note-1');
      expect(stored.data?.title, 'Groceries');
    });

    test('should persist an updated note', () async {
      await service.create(_note());

      final result = await service.update(_note(title: 'Weekly groceries'));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('note-1');
      expect(stored.data?.title, 'Weekly groceries');
    });

    test('should persist a reorder batch', () async {
      await service.create(_note());
      await service.create(_note(id: 'note-2', order: 1));

      final result = await service.updateBulk([_note(order: 1), _note(id: 'note-2', order: 0)]);

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('note-1');
      expect(stored.data?.order, 1);
    });

    test('should propagate a repository create failure', () async {
      final failingService = NotesService(
        _FailingNotesRepository(StorageGateway.instance, logger),
        logger,
        reminders: ThrowingReminderService(logger),
      );

      expectWriteFailure(await failingService.create(_note()));
    });

    test('should propagate a repository soft delete failure', () async {
      final failingService = NotesService(
        _FailingNotesRepository(StorageGateway.instance, logger),
        logger,
        reminders: ThrowingReminderService(logger),
      );

      expectWriteFailure(await failingService.softDelete('note-1'));
    });
  });

  group('NotesService reminders', () {
    test('should succeed without scheduling when the todo has no reminder', () async {
      final result = await service.scheduleTodoReminder(_todo());

      expect(result.isSuccess, isTrue);
    });

    test('should return a failure instead of throwing when scheduling fails', () async {
      final result = await service.scheduleTodoReminder(_todo(reminderAt: DateTime(2026, 1, 2)));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });

    test('should return a failure instead of throwing when the tap handler fails', () async {
      final result = await service.handleTodoReminderTap(_todo());

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });
  });
}
