import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/notes/note.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class NotesRepository extends BaseRepository<Note> {
  Future<Result<List<Note>, AppError>> searchText(String text);
  Future<Result<List<Note>, AppError>> byTag(String tag);
}

class NotesRepositoryImpl extends BaseRepositoryImpl<Note>
    implements NotesRepository {
  NotesRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'notes';

  @override
  Note fromJson(Map<String, dynamic> json) => Note.fromJson(json);

  @override
  Future<Result<List<Note>, AppError>> byTag(String tag) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final result = all.data!
        .where((item) => item.tags.any((entry) => entry.toLowerCase() == tag.toLowerCase()))
        .toList(growable: false);

    return Success(result);
  }

  @override
  Future<Result<List<Note>, AppError>> searchText(String text) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final term = text.toLowerCase();
    final result = all.data!
        .where((item) => item.title.toLowerCase().contains(term) || item.content.toLowerCase().contains(term))
        .toList(growable: false);

    return Success(result);
  }
}
