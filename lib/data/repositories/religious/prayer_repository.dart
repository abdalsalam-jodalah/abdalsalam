import '../../../data/models/religious/prayer_log.dart';
import '../base_repository_impl.dart';

class PrayerRepository extends BaseRepositoryImpl<PrayerLog> {
  PrayerRepository(super.storage, super.logger);

  @override
  String get tableName => 'prayer_logs';

  @override
  PrayerLog fromJson(Map<String, dynamic> json) {
    return PrayerLog.fromJson(json);
  }
}
