import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/notes/note.dart';
import 'package:abdalsalam/data/models/notes/note_category.dart';
import 'package:abdalsalam/data/models/notes/todo.dart';
import 'package:flutter_test/flutter_test.dart';

const String createdAtIso = '2026-01-01T08:00:00.000';
final DateTime createdAt = DateTime(2026, 1, 1, 8);

Map<String, dynamic> baseJson() => <String, dynamic>{
      'id': 'record-1',
      'createdAt': createdAtIso,
      'userId': 'user1',
    };

void main() {
  group('Note.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final note = Note(
        id: 'note-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        deletedAt: DateTime(2026, 1, 3),
        userId: 'user1',
        title: 'Title',
        content: 'Body',
        tags: const <String>['idea'],
        categoryId: 'category-1',
        pinned: true,
        archived: true,
        attachments: const <String>['file.png'],
        color: '#FFFFFF',
        order: 4,
      );

      final parsed = Note.fromJson(note.toJson());

      expect(parsed.toJson(), note.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = Note.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.title, '');
      expect(parsed.content, '');
      expect(parsed.tags, isEmpty);
      expect(parsed.attachments, isEmpty);
      expect(parsed.pinned, isFalse);
      expect(parsed.archived, isFalse);
      expect(parsed.categoryId, isNull);
      expect(parsed.order, 0);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['order'] = '3'
        ..['pinned'] = 1
        ..['archived'] = 'true'
        ..['tags'] = <dynamic>['a', 2];

      final parsed = Note.fromJson(json);

      expect(parsed.order, 3);
      expect(parsed.pinned, isTrue);
      expect(parsed.archived, isTrue);
      expect(parsed.tags, <String>['a']);
    });

    test('should fall back when dates are invalid', () {
      final json = baseJson()
        ..['updatedAt'] = 'not-a-date'
        ..['deletedAt'] = 'not-a-date';

      final parsed = Note.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = baseJson()..remove('id');

      expect(() => Note.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('NoteCategory.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final category = NoteCategory(
        id: 'category-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        name: 'Work',
        icon: 'work',
        color: '#000000',
        type: NoteCategoryType.todo,
        parentId: 'category-0',
      );

      final parsed = NoteCategory.fromJson(category.toJson());

      expect(parsed.toJson(), category.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = NoteCategory.fromJson(json);

      expect(parsed.name, '');
      expect(parsed.icon, '');
      expect(parsed.color, '');
      expect(parsed.type, NoteCategoryType.note);
      expect(parsed.parentId, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()..['name'] = 42;

      final parsed = NoteCategory.fromJson(json);

      expect(parsed.name, '42');
    });

    test('should return null when an optional date is invalid', () {
      final json = baseJson()..['deletedAt'] = 'not-a-date';

      final parsed = NoteCategory.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should fall back when the type enum is unknown', () {
      final json = baseJson()..['type'] = 'folder';

      final parsed = NoteCategory.fromJson(json);

      expect(parsed.type, NoteCategoryType.note);
    });

    test('should throw CorruptDataError when createdAt is invalid', () {
      final json = baseJson()..['createdAt'] = 'not-a-date';

      expect(() => NoteCategory.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('Todo.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final todo = Todo(
        id: 'todo-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        title: 'Call',
        description: 'Call the bank',
        dueDate: DateTime(2026, 1, 5),
        priority: TodoPriority.high,
        status: TodoStatus.done,
        categoryId: 'category-1',
        tags: const <String>['errand'],
        reminderAt: DateTime(2026, 1, 4, 9),
        parentTodoId: 'todo-0',
        order: 2,
        habitId: 'habit-1',
      );

      final parsed = Todo.fromJson(todo.toJson());

      expect(parsed.toJson(), todo.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = Todo.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.priority, TodoPriority.medium);
      expect(parsed.status, TodoStatus.pending);
      expect(parsed.dueDate, isNull);
      expect(parsed.reminderAt, isNull);
      expect(parsed.tags, isEmpty);
      expect(parsed.order, 0);
      expect(parsed.habitId, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['order'] = 2.0
        ..['dueDate'] = DateTime(2026, 1, 5).millisecondsSinceEpoch;

      final parsed = Todo.fromJson(json);

      expect(parsed.order, 2);
      expect(parsed.dueDate, DateTime(2026, 1, 5));
    });

    test('should return null when optional dates are invalid', () {
      final json = baseJson()
        ..['dueDate'] = 'not-a-date'
        ..['reminderAt'] = 'not-a-date';

      final parsed = Todo.fromJson(json);

      expect(parsed.dueDate, isNull);
      expect(parsed.reminderAt, isNull);
    });

    test('should fall back when enum values are unknown', () {
      final json = baseJson()
        ..['priority'] = 'urgent'
        ..['status'] = 'archived';

      final parsed = Todo.fromJson(json);

      expect(parsed.priority, TodoPriority.medium);
      expect(parsed.status, TodoStatus.pending);
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = baseJson()..remove('id');

      expect(() => Todo.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
