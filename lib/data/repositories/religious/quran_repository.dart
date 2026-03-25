import '../../../data/models/religious/quran_progress.dart';
import '../base_repository_impl.dart';

class QuranRepository extends BaseRepositoryImpl<QuranProgress> {
  QuranRepository(super.logger);

  @override
  String get tableName => 'quran_progress';

  @override
  QuranProgress fromJson(Map<String, dynamic> json) {
    return QuranProgress.fromJson(json);
  }
}
