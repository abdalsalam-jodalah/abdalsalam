// lib/data/repositories/enhancements/enhancement_note_repository.dart: storage access for app enhancement notes.
import '../../models/enhancements/enhancement_note.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class EnhancementNoteRepository extends BaseRepository<EnhancementNote> {}

class EnhancementNoteRepositoryImpl extends BaseRepositoryImpl<EnhancementNote> implements EnhancementNoteRepository {
  EnhancementNoteRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'app_enhancement_notes';

  @override
  EnhancementNote fromJson(Map<String, dynamic> json) => EnhancementNote.fromJson(json);
}
