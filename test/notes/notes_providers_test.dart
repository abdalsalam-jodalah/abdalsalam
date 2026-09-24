import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/notes/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notes_fakes.dart';

void main() {
  group('activeNotesProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeNotesRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        notesRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeNotesProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the notes sorted by order on success', () async {
      final repo = FakeNotesRepository([
        buildNote(id: 'n2', order: 1),
        buildNote(id: 'n1', order: 0),
      ]);
      final container = ProviderContainer(overrides: [
        notesRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final notes = await container.read(activeNotesProvider.future);
      expect(notes.map((note) => note.id), ['n1', 'n2']);
    });
  });

  group('activeTodosProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeTodoRepository()..shouldFailGetActive = true;
      final container = ProviderContainer(overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeTodosProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the todos sorted by order on success', () async {
      final repo = FakeTodoRepository([
        buildTodo(id: 't2', order: 1),
        buildTodo(id: 't1', order: 0),
      ]);
      final container = ProviderContainer(overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final todos = await container.read(activeTodosProvider.future);
      expect(todos.map((todo) => todo.id), ['t1', 't2']);
    });
  });

  group('todosForHabitProvider', () {
    test('surfaces a typed error when the repository fails', () async {
      final repo = FakeTodoRepository()..shouldFailQuery = true;
      final container = ProviderContainer(overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        container.read(todosForHabitProvider('habit-1').future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns todos for the habit on success', () async {
      final repo = FakeTodoRepository([
        buildTodo(id: 't1', habitId: 'habit-1'),
        buildTodo(id: 't2', habitId: 'habit-2'),
      ]);
      final container = ProviderContainer(overrides: [
        todoRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      final todos = await container.read(todosForHabitProvider('habit-1').future);
      expect(todos.map((todo) => todo.id), ['t1']);
    });
  });
}
