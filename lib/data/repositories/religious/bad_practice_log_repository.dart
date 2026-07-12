import '../../models/religious/bad_practice_log.dart';
import '../base_repository_impl.dart';

class BadPracticeLogRepository extends BaseRepositoryImpl<BadPracticeLog> {
  BadPracticeLogRepository(super.storage, super.logger);

  @override
  String get tableName => 'bad_practice_logs';

  @override
  BadPracticeLog fromJson(Map<String, dynamic> json) {
    return BadPracticeLog.fromJson(json);
  }
}
