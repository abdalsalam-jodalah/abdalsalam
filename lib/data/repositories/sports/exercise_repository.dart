import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/exercise.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class ExerciseRepository extends BaseRepository<Exercise> {
  Future<Result<List<Exercise>, AppError>> getByCategory(String categoryId);
}

class ExerciseRepositoryImpl extends BaseRepositoryImpl<Exercise> implements ExerciseRepository {
  ExerciseRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_exercises';

  @override
  Exercise fromJson(Map<String, dynamic> json) => Exercise.fromJson(json);

  @override
  Future<Result<List<Exercise>, AppError>> getByCategory(String categoryId) async {
    final result = await query(<String, dynamic>{'categoryId': categoryId});
    if (result.isFailure) {
      return result;
    }
    final active = result.data!.where((exercise) => exercise.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return Success(active);
  }
}
