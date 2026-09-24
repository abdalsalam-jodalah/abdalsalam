import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/notes/notes_repository.dart';
import '../../../data/repositories/notes/todo_repository.dart';
import '../../../data/models/notes/note.dart';
import '../../../data/models/notes/todo.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/notes_service.dart';
import '../services/todo_service.dart';

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

final notesServiceProvider = Provider<NotesService>((ref) {
  return NotesService(
    ref.watch(notesRepositoryProvider),
    LoggerService.forModule('NotesService', moduleType: logic.ModuleType.service),
    reminders: ref.watch(reminderServiceProvider),
  );
});

final todoServiceProvider = Provider<TodoService>((ref) {
  return TodoService(
    ref.watch(todoRepositoryProvider),
    LoggerService.forModule('TodoService', moduleType: logic.ModuleType.service),
  );
});

final activeNotesProvider = FutureProvider<List<Note>>((ref) async {
  final service = ref.watch(notesServiceProvider);
  final result = await service.getActive();
  final notes = [...result.getOrThrow()]..sort((a, b) => a.order.compareTo(b.order));
  return notes;
});

final activeTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final service = ref.watch(todoServiceProvider);
  final result = await service.getActive();
  final todos = [...result.getOrThrow()]..sort((a, b) => a.order.compareTo(b.order));
  return todos;
});

final todosForHabitProvider =
    FutureProvider.autoDispose.family<List<Todo>, String>((ref, habitId) async {
  final service = ref.watch(todoServiceProvider);
  final result = await service.filter(<String, dynamic>{'habitId': habitId});
  return result.getOrThrow();
});
