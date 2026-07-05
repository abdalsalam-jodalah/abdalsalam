import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/notes/note_category.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class NoteCategoryRepository extends BaseRepository<NoteCategory> {
  Future<Result<List<NoteCategory>, AppError>> byType(NoteCategoryType type);
}

class NoteCategoryRepositoryImpl extends BaseRepositoryImpl<NoteCategory>
    implements NoteCategoryRepository {
  NoteCategoryRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'note_categories';

  @override
  NoteCategory fromJson(Map<String, dynamic> json) => NoteCategory.fromJson(json);

  @override
  Future<Result<List<NoteCategory>, AppError>> byType(NoteCategoryType type) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final result = all.data!
        .where((item) => item.type == type)
        .toList(growable: false);

    return Success(result);
  }
}
