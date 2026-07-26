import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/sports/exercise_category.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class ExerciseCategoryRepository extends BaseRepository<ExerciseCategory> {
  Future<Result<List<ExerciseCategory>, AppError>> getAllOrdered();
}

class ExerciseCategoryRepositoryImpl extends BaseRepositoryImpl<ExerciseCategory>
    implements ExerciseCategoryRepository {
  ExerciseCategoryRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'sport_exercise_categories';

  @override
  ExerciseCategory fromJson(Map<String, dynamic> json) => ExerciseCategory.fromJson(json);

  @override
  Future<Result<List<ExerciseCategory>, AppError>> getAllOrdered() async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final sorted = [...result.data!]..sort((a, b) => a.order.compareTo(b.order));
    return Success(sorted);
  }
}
