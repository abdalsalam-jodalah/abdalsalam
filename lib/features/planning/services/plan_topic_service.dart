import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/validation/validation_result_factory.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/planning/plan_topic.dart';
import '../../../data/repositories/planning/plan_topic_repository.dart';
import '../../../shared/services/base_service_impl.dart';

class PlanTopicService extends BaseServiceImpl<PlanTopic> {
  static const String userIdField = 'userId';
  static const String titleField = 'title';
  static const String parentTopicIdField = 'parentTopicId';

  PlanTopicService(PlanTopicRepository super.repository, super.logger);

  PlanTopicRepository get _repo => repository as PlanTopicRepository;

  @override
  String get serviceName => 'PlanTopicService';

  @override
  String get version => '1.0.0';

  @override
  PlanTopic fromJson(Map<String, dynamic> json) => PlanTopic.fromJson(json);

  @override
  Result<void, AppError> validate(PlanTopic entity) {
    return ValidationResultFactory.fromFieldErrors(
      ValidationUtils.collect([
        MapEntry(userIdField, ValidationUtils.requiredField(entity.userId, userIdField)),
        MapEntry(titleField, ValidationUtils.requiredField(entity.title, titleField)),
        MapEntry(
          parentTopicIdField,
          ValidationUtils.selfReference(
            id: entity.id,
            referenceId: entity.parentTopicId,
            fieldName: parentTopicIdField,
          ),
        ),
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
      'totalTopics': active.data!.length,
      'rootTopics': active.data!.where((topic) => topic.parentTopicId == null).length,
    });
  }

  Future<Result<List<PlanTopic>, AppError>> getChildren(String parentTopicId) {
    return _repo.getChildren(parentTopicId);
  }

  Future<Result<List<PlanTopic>, AppError>> getRootTopics() {
    return _repo.getRootTopics();
  }
}
