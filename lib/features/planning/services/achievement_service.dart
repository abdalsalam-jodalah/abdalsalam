import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/achievement.dart';
import '../../../data/repositories/planning/achievement_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class AchievementService extends BaseServiceImpl<Achievement> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';

  AchievementService(AchievementRepository super.repository, super.logger);

  AchievementRepository get _repo => repository as AchievementRepository;

  @override
  String get serviceName => 'AchievementService';

  @override
  String get version => '1.0.0';

  @override
  Achievement fromJson(Map<String, dynamic> json) => Achievement.fromJson(json);

  @override
  Result<void, AppError> validate(Achievement entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
      ]),
    );
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final active = await getActive();
    if (active.isFailure) {
      return Failure(active.error!);
    }
    return Success(<String, dynamic>{
      'totalAchievements': active.data!.length,
    });
  }

  Future<Result<List<Achievement>, AppError>> getByGoal(String goalId) {
    return _repo.getByGoal(goalId);
  }
}
