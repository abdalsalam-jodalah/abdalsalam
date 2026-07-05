import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/achievement.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class AchievementRepository extends BaseRepository<Achievement> {
  Future<Result<List<Achievement>, AppError>> getByGoal(String goalId);
}

class AchievementRepositoryImpl extends BaseRepositoryImpl<Achievement>
    implements AchievementRepository {
  AchievementRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_achievements';

  @override
  Achievement fromJson(Map<String, dynamic> json) => Achievement.fromJson(json);

  @override
  Future<Result<List<Achievement>, AppError>> getByGoal(String goalId) {
    return query(<String, dynamic>{'goalId': goalId});
  }
}
