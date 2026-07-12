import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/religious/quran_reading.dart';
import '../base_repository_impl.dart';

class QuranReadingRepository extends BaseRepositoryImpl<QuranReading> {
  QuranReadingRepository(super.storage, super.logger);

  @override
  String get tableName => 'quran_readings';

  @override
  QuranReading fromJson(Map<String, dynamic> json) {
    return QuranReading.fromJson(json);
  }

  Future<Result<List<QuranReading>, AppError>> getBySurah(int surahNumber) {
    return query(<String, dynamic>{'surahNumber': surahNumber});
  }

  Future<Result<List<QuranReading>, AppError>> getMemorized() {
    return query(<String, dynamic>{'memorized': true});
  }
}
