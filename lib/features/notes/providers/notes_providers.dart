import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/notes/notes_repository.dart';
import '../../../data/repositories/notes/todo_repository.dart';
import '../../../data/models/notes/note.dart';
import '../../../data/models/notes/todo.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';

const String notesUserId = 'user1';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'NotesRepository',
    moduleType: logic.ModuleType.repository,
  );
  return NotesRepositoryImpl(storage, logger);
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'TodoRepository',
    moduleType: logic.ModuleType.repository,
  );
  return TodoRepositoryImpl(storage, logger);
});

final activeNotesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(notesRepositoryProvider);
  final result = await repo.getActive();
  final notes = [...(result.data ?? <Note>[])]..sort((a, b) => a.order.compareTo(b.order));
  return notes;
});

final activeTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  final result = await repo.getActive();
  final todos = [...(result.data ?? <Todo>[])]..sort((a, b) => a.order.compareTo(b.order));
  return todos;
});
