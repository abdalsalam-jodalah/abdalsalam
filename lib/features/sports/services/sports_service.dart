import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/sports/workout.dart';
import '../../../data/repositories/sports/sports_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class SportsService extends BaseServiceImpl<Workout> {
  SportsService(super.repository, super.logger);

  SportsRepository get _repo => repository as SportsRepository;

  @override
  String get serviceName => 'SportsService';

  @override
  String get version => '2.0.0';

  @override
  Workout fromJson(Map<String, dynamic> json) => Workout.fromJson(json);

  @override
  Result<void, AppError> validate(Workout entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.name.trim().isEmpty) {
      return Failure(ValidationError('name is required'));
    }
    if (entity.endTime.isBefore(entity.startTime)) {
      return Failure(ValidationError('endTime must be after startTime'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!;
    final totalDuration = rows.fold<int>(0, (sum, item) => sum + item.durationMinutes);
    final calories = rows.fold<int>(0, (sum, item) => sum + item.caloriesBurned);

    return Success(<String, dynamic>{
      'totalWorkouts': rows.length,
      'totalDuration': totalDuration,
      'caloriesBurned': calories,
      'personalRecords': <String, dynamic>{},
      'progress': rows.isEmpty ? 0.0 : totalDuration / rows.length,
    });
  }

  Map<String, int> personalRecordsByExercise(List<Workout> workouts) {
    final out = <String, int>{};
    for (final item in workouts) {
      final current = out[item.type] ?? 0;
      if (item.durationMinutes > current) {
        out[item.type] = item.durationMinutes;
      }
    }
    return out;
  }
}
