import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/workout.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class SportsRepository extends BaseRepository<Workout> {
  Future<Result<List<Workout>, AppError>> getByType(String type);
}

class SportsRepositoryImpl extends BaseRepositoryImpl<Workout>
    implements SportsRepository {
  SportsRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'workouts';

  @override
  Workout fromJson(Map<String, dynamic> json) => Workout.fromJson(json);

  @override
  Future<Result<List<Workout>, AppError>> getByType(String type) {
    return query(<String, dynamic>{'type': type});
  }
}
