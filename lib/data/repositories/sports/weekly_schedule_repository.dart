import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/weekly_schedule_entry.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class WeeklyScheduleRepository extends BaseRepository<WeeklyScheduleEntry> {
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getByDayOfWeek(int dayOfWeek);
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getFullWeek();
}

class WeeklyScheduleRepositoryImpl extends BaseRepositoryImpl<WeeklyScheduleEntry>
    implements WeeklyScheduleRepository {
  WeeklyScheduleRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_weekly_schedule';

  @override
  WeeklyScheduleEntry fromJson(Map<String, dynamic> json) => WeeklyScheduleEntry.fromJson(json);

  @override
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getByDayOfWeek(int dayOfWeek) async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final matches = result.data!
        .where((entry) => entry.dayOfWeek == dayOfWeek && entry.enabled)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Success(matches);
  }

  @override
  Future<Result<List<WeeklyScheduleEntry>, AppError>> getFullWeek() async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final sorted = [...result.data!]
      ..sort((a, b) {
        final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
        return dayCompare != 0 ? dayCompare : a.order.compareTo(b.order);
      });
    return Success(sorted);
  }
}
