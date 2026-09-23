import 'package:flutter/widgets.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/notes/note.dart';
import '../../../data/models/notes/todo.dart';
import '../../../data/repositories/notes/notes_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';

class NotesService extends BaseServiceImpl<Note> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';

  final ReminderService reminders;

  NotesService(NotesRepository super.repository, super.logger, {required this.reminders});

  NotesRepository get _repo => repository as NotesRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  @override
  String get serviceName => 'NotesService';

  @override
  String get version => '2.0.0';

  @override
  Note fromJson(Map<String, dynamic> json) => Note.fromJson(json);

  @override
  Result<void, AppError> validate(Note entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
      ]),
    );
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
    final reminderAt = todo.reminderAt;
    if (reminderAt == null) {
      return const Success(null);
    }
    try {
      await reminders.schedule(
        ReminderPayload(
          module: ReminderModule.notes,
          targetId: todo.id,
          title: 'Todo reminder',
          body: todo.title,
          scheduledAt: reminderAt,
        ),
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.scheduleTodoReminder', stackTrace: st));
    }
  }

  Future<Result<void, AppError>> handleTodoReminderTap(Todo todo) async {
    try {
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
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.handleTodoReminderTap', stackTrace: st));
    }
  }
}
