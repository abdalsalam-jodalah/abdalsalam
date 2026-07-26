import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../data/repositories/health/health_metric_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class HealthMetricService extends BaseServiceImpl<HealthMetric> {
  HealthMetricService(HealthMetricRepository super.repository, super.logger);

  HealthMetricRepository get _repo => repository as HealthMetricRepository;

  @override
  String get serviceName => 'HealthMetricService';

  @override
  String get version => '1.0.0';

  @override
  HealthMetric fromJson(Map<String, dynamic> json) => HealthMetric.fromJson(json);

  @override
  Result<void, AppError> validate(HealthMetric entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.metricType.trim().isEmpty) {
      return Failure(ValidationError('metricType is required'));
    }
    if (entity.unit.trim().isEmpty) {
      return Failure(ValidationError('unit is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    return Success(<String, dynamic>{
      'totalMetrics': all.data!.length,
      'latestByType': latestByType(all.data!),
    });
  }

  /// Returns each metric type's most recently measured value.
  Map<String, HealthMetric> latestByType(List<HealthMetric> metrics) {
    final out = <String, HealthMetric>{};
    for (final metric in metrics) {
      final current = out[metric.metricType];
      if (current == null || metric.measuredAt.isAfter(current.measuredAt)) {
        out[metric.metricType] = metric;
      }
    }
    return out;
  }

  Future<Result<List<HealthMetric>, AppError>> getTrend(String metricType) {
    return _repo.getByType(metricType);
  }
}
