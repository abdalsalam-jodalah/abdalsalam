import 'package:flutter/widgets.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/notes/note.dart';
import '../../../data/models/notes/todo.dart';
import '../../../data/repositories/notes/notes_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class NotesService extends BaseServiceImpl<Note> {
  final ReminderService reminders;

  NotesService(super.repository, super.logger, {required this.reminders});

  NotesRepository get _repo => repository as NotesRepository;

  @override
  String get serviceName => 'NotesService';

  @override
  String get version => '2.0.0';

  @override
  Note fromJson(Map<String, dynamic> json) => Note.fromJson(json);

  @override
  Result<void, AppError> validate(Note entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.title.trim().isEmpty) {
      return Failure(ValidationError('title is required'));
    }
    return const Success(null);
  }

  Result<void, AppError> validateTodo(Todo todo) {
    if (todo.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (todo.title.trim().isEmpty) {
      return Failure(ValidationError('title is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final notes = await _repo.getActive();
    if (notes.isFailure) {
      return Failure(notes.error!);
    }
    final pinned = notes.data!.where((note) => note.pinned).length;
    return Success(<String, dynamic>{
      'totalNotes': notes.data!.length,
      'pinnedNotes': pinned,
    });
  }

  Future<Result<List<Note>, AppError>> fullTextSearch(String query) {
    return _repo.searchText(query);
  }

  Future<Result<List<Note>, AppError>> filterByTag(String tag) {
    return _repo.byTag(tag);
  }

  TextEditingController createRichTextController({String? initialPlainText}) {
    return TextEditingController(text: initialPlainText ?? '');
  }

  Future<Result<void, AppError>> scheduleTodoReminder(Todo todo) async {
    if (todo.reminderAt == null) {
      return const Success(null);
    }
    await reminders.schedule(
      ReminderPayload(
        module: ReminderModule.notes,
        targetId: todo.id,
        title: 'Todo reminder',
        body: todo.title,
        scheduledAt: todo.reminderAt!,
      ),
    );
    return const Success(null);
  }

  Future<Result<void, AppError>> handleTodoReminderTap(Todo todo) async {
    reminders.handleNotificationTap(
      ReminderPayload(
        module: ReminderModule.notes,
        targetId: todo.id,
        title: 'Open todo',
        body: todo.title,
        scheduledAt: DateTime.now(),
      ),
    );
    return const Success(null);
  }
}
