import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/health/health_metric.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class HealthMetricRepository extends BaseRepository<HealthMetric> {
  Future<Result<List<HealthMetric>, AppError>> getByType(String metricType);
}

class HealthMetricRepositoryImpl extends BaseRepositoryImpl<HealthMetric>
    implements HealthMetricRepository {
  HealthMetricRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'health_metrics';

  @override
  HealthMetric fromJson(Map<String, dynamic> json) => HealthMetric.fromJson(json);

  @override
  Future<Result<List<HealthMetric>, AppError>> getByType(String metricType) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!.where((metric) => metric.metricType == metricType).toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return Success(rows);
  }
}
