import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/planning/plan_topic.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class PlanTopicRepository extends BaseRepository<PlanTopic> {
  Future<Result<List<PlanTopic>, AppError>> getChildren(String parentTopicId);
  Future<Result<List<PlanTopic>, AppError>> getRootTopics();
}

class PlanTopicRepositoryImpl extends BaseRepositoryImpl<PlanTopic>
    implements PlanTopicRepository {
  PlanTopicRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'life_plan_topics';

  @override
  PlanTopic fromJson(Map<String, dynamic> json) => PlanTopic.fromJson(json);

  @override
  Future<Result<List<PlanTopic>, AppError>> getChildren(String parentTopicId) {
    return query(<String, dynamic>{'parentTopicId': parentTopicId});
  }

  @override
  Future<Result<List<PlanTopic>, AppError>> getRootTopics() async {
    final result = await getActive();
    if (result.isFailure) {
      return Failure(result.error!);
    }

    final roots = result.data!.where((topic) => topic.parentTopicId == null).toList(growable: false);
    return Success(roots);
  }
}
