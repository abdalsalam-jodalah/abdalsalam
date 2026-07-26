import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sleep/sleep_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class SleepLogRepository extends BaseRepository<SleepLog> {}

class SleepLogRepositoryImpl extends BaseRepositoryImpl<SleepLog> implements SleepLogRepository {
  SleepLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sleep_logs';

  @override
  SleepLog fromJson(Map<String, dynamic> json) => SleepLog.fromJson(json);

  @override
  Future<Result<List<SleepLog>, AppError>> getByDateRange(DateTime start, DateTime end) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!
        .where((log) => !log.sleepStart.isBefore(start) && !log.sleepStart.isAfter(end))
        .toList()
      ..sort((a, b) => a.sleepStart.compareTo(b.sleepStart));
    return Success(rows);
  }
}
