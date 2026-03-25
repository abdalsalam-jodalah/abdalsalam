import '../../models/religious/prayer_log.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class PrayerRepository extends BaseRepository<PrayerLog> {
  Future<Result<List<PrayerLog>, AppError>> getByPrayerType(PrayerName prayer);
}

class PrayerRepositoryImpl extends BaseRepositoryImpl<PrayerLog>
    implements PrayerRepository {
  PrayerRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'prayer_logs';

  @override
  PrayerLog fromJson(Map<String, dynamic> json) {
    return PrayerLog.fromJson(json);
  }

  @override
  Future<Result<List<PrayerLog>, AppError>> getByPrayerType(PrayerName prayer) {
    return query(<String, dynamic>{'prayerName': prayer.name});
  }
}
