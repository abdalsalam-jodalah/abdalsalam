import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/food/food_log.dart';
import '../../../data/repositories/food/food_log_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class FoodLogService extends BaseServiceImpl<FoodLog> {
  FoodLogService(FoodLogRepository super.repository, super.logger);

  FoodLogRepository get _repo => repository as FoodLogRepository;

  @override
  String get serviceName => 'FoodLogService';

  @override
  String get version => '1.0.0';

  @override
  FoodLog fromJson(Map<String, dynamic> json) => FoodLog.fromJson(json);

  @override
  Result<void, AppError> validate(FoodLog entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.category.trim().isEmpty) {
      return Failure(ValidationError('category is required'));
    }
    if (entity.dishName.trim().isEmpty) {
      return Failure(ValidationError('dishName is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final now = DateTime.now();
    final todayLogs = all.data!.where((log) => _isSameDay(log.loggedAt, now)).toList();

    return Success(<String, dynamic>{
      'totalLogs': all.data!.length,
      'todayCalories': _sumNonNull(todayLogs.map((log) => log.calories)),
      'todayProteinGrams': _sumNonNull(todayLogs.map((log) => log.proteinGrams)),
      'todayFatGrams': _sumNonNull(todayLogs.map((log) => log.fatGrams)),
      'todayCarbGrams': _sumNonNull(todayLogs.map((log) => log.carbGrams)),
      'todayMealCountByCategory': _countByCategory(todayLogs),
    });
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  double _sumNonNull(Iterable<double?> values) =>
      values.whereType<double>().fold(0, (sum, value) => sum + value);

  Map<String, int> _countByCategory(List<FoodLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      counts[log.category] = (counts[log.category] ?? 0) + 1;
    }
    return counts;
  }

  Future<Result<List<FoodLog>, AppError>> getByCategory(String category) {
    return _repo.getByCategory(category);
  }
}
