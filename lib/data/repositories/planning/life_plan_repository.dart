import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/life_plan.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class LifePlanRepository extends BaseRepository<LifePlan> {
  Future<Result<LifePlan?, AppError>> getForUser(String userId);
}

class LifePlanRepositoryImpl extends BaseRepositoryImpl<LifePlan>
    implements LifePlanRepository {
  LifePlanRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_plans';

  @override
  LifePlan fromJson(Map<String, dynamic> json) => LifePlan.fromJson(json);

  @override
  Future<Result<LifePlan?, AppError>> getForUser(String userId) async {
    final result = await getByUserId(userId);
    if (result.isFailure) {
      return Failure(result.error!);
    }

    final active = result.data!.where((item) => item.isActive).toList(growable: false);
    return Success(active.isEmpty ? null : active.first);
  }
}
