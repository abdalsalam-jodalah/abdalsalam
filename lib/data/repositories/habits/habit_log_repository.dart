import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/habits/habit_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class HabitLogRepository extends BaseRepository<HabitLog> {
  Future<Result<List<HabitLog>, AppError>> getByHabit(String habitId);

  Future<Result<List<HabitLog>, AppError>> getByHabitAndDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  );
}

class HabitLogRepositoryImpl extends BaseRepositoryImpl<HabitLog>
    implements HabitLogRepository {
  HabitLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'habit_logs';

  @override
  HabitLog fromJson(Map<String, dynamic> json) => HabitLog.fromJson(json);

  @override
  Future<Result<List<HabitLog>, AppError>> getByHabit(String habitId) async {
    final result = await query(<String, dynamic>{'habitId': habitId});
    if (result.isFailure) {
      return result;
    }
    final sorted = [...result.data!]..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return Success(sorted);
  }

  @override
  Future<Result<List<HabitLog>, AppError>> getByHabitAndDateRange(
    String habitId,
    DateTime start,
    DateTime end,
  ) async {
    final result = await getByHabit(habitId);
    if (result.isFailure) {
      return result;
    }
    final filtered = result.data!
        .where((log) => !log.completedAt.isBefore(start) && !log.completedAt.isAfter(end))
        .toList(growable: false);
    return Success(filtered);
  }
}
