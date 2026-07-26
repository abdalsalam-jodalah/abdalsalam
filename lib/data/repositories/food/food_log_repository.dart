import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/food/food_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class FoodLogRepository extends BaseRepository<FoodLog> {
  Future<Result<List<FoodLog>, AppError>> getByCategory(String category);
}

class FoodLogRepositoryImpl extends BaseRepositoryImpl<FoodLog> implements FoodLogRepository {
  FoodLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'food_logs';

  @override
  FoodLog fromJson(Map<String, dynamic> json) => FoodLog.fromJson(json);

  @override
  Future<Result<List<FoodLog>, AppError>> getByDateRange(DateTime start, DateTime end) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!
        .where((log) => !log.loggedAt.isBefore(start) && !log.loggedAt.isAfter(end))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return Success(rows);
  }

  @override
  Future<Result<List<FoodLog>, AppError>> getByCategory(String category) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!.where((log) => log.category == category).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return Success(rows);
  }
}
