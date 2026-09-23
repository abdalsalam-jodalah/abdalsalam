import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/life_plan.dart';
import '../../../data/repositories/planning/life_plan_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class LifePlanService extends BaseServiceImpl<LifePlan> {
  static const String userIdField = 'userId';

  LifePlanService(LifePlanRepository super.repository, super.logger);

  LifePlanRepository get _repo => repository as LifePlanRepository;

  @override
  String get serviceName => 'LifePlanService';

  @override
  String get version => '1.0.0';

  @override
  LifePlan fromJson(Map<String, dynamic> json) => LifePlan.fromJson(json);

  @override
  Result<void, AppError> validate(LifePlan entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
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
      'totalPlans': active.data!.length,
    });
  }

  Future<Result<LifePlan?, AppError>> getForUser(String userId) {
    return _repo.getForUser(userId);
  }
}
