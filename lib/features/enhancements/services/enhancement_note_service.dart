// lib/features/enhancements/services/enhancement_note_service.dart: rules and ordering for app enhancement notes.
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/enhancements/enhancement_note.dart';
import '../../../data/repositories/enhancements/enhancement_note_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class EnhancementNoteService extends BaseServiceImpl<EnhancementNote> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';

  EnhancementNoteService(EnhancementNoteRepository super.repository, super.logger);

  @override
  String get serviceName => 'EnhancementNoteService';

  @override
  String get version => '1.0.0';

  @override
  EnhancementNote fromJson(Map<String, dynamic> json) => EnhancementNote.fromJson(json);

  @override
  Result<void, AppError> validate(EnhancementNote entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
      ]),
    );
  }

  Future<Result<void, AppError>> setDone(EnhancementNote note, {required bool isDone}) {
    final now = DateTime.now();
    return update(
      note.copyWith(
        isDone: isDone,
        completedAt: isDone ? now : null,
        clearCompletedAt: !isDone,
        updatedAt: now,
      ),
    );
  }

  static List<EnhancementNote> sortForDisplay(Iterable<EnhancementNote> notes) {
    final sorted = notes.toList();
    sorted.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      if (a.isDone) {
        return (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt);
      }
      final byPriority = b.priority.index.compareTo(a.priority.index);
      return byPriority != 0 ? byPriority : b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    final notes = active.data!;
    return Success(<String, dynamic>{
      'totalNotes': notes.length,
      'openNotes': notes.where((note) => !note.isDone).length,
      'doneNotes': notes.where((note) => note.isDone).length,
    });
  }
}
