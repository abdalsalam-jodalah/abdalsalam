import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/blood_test.dart';
import '../../../data/repositories/health/blood_test_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class BloodTestService extends BaseServiceImpl<BloodTest> {
  BloodTestService(BloodTestRepository super.repository, super.logger);

  BloodTestRepository get _repo => repository as BloodTestRepository;

  @override
  String get serviceName => 'BloodTestService';

  @override
  String get version => '1.0.0';

  @override
  BloodTest fromJson(Map<String, dynamic> json) => BloodTest.fromJson(json);

  @override
  Result<void, AppError> validate(BloodTest entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.testType.trim().isEmpty) {
      return Failure(ValidationError('testType is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final upcoming = await _repo.getUpcoming();
    if (upcoming.isFailure) {
      return Failure(upcoming.error!);
    }
    final completed = await _repo.getCompleted();
    if (completed.isFailure) {
      return Failure(completed.error!);
    }

    final nextTest = upcoming.data!.isEmpty ? null : upcoming.data!.first;

    return Success(<String, dynamic>{
      'scheduledCount': upcoming.data!.length,
      'completedCount': completed.data!.length,
      'nextTestDate': nextTest?.scheduledDate.toIso8601String(),
    });
  }

  Future<Result<List<BloodTest>, AppError>> getUpcoming() => _repo.getUpcoming();

  Future<Result<List<BloodTest>, AppError>> getCompleted() => _repo.getCompleted();

  /// Marks a scheduled test as completed with its results.
  Future<Result<void, AppError>> completeTest(
    BloodTest test, {
    required Map<String, dynamic> results,
    DateTime? completedDate,
  }) async {
    final updated = test.copyWith(
      completedDate: completedDate ?? DateTime.now(),
      results: results,
      updatedAt: DateTime.now(),
    );
    return update(updated);
  }
}
