import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/doctor_visit.dart';
import '../../../data/repositories/health/doctor_visit_repository.dart';
import '../../../shared/services/attachment_storage_service.dart';
import '../../../shared/services/base_service_impl.dart';

class DoctorVisitService extends BaseServiceImpl<DoctorVisit> {
  final AttachmentStorageService attachments;

  DoctorVisitService(
    DoctorVisitRepository super.repository,
    super.logger, {
    required this.attachments,
  });

  DoctorVisitRepository get _repo => repository as DoctorVisitRepository;

  @override
  String get serviceName => 'DoctorVisitService';

  @override
  String get version => '1.0.0';

  @override
  DoctorVisit fromJson(Map<String, dynamic> json) => DoctorVisit.fromJson(json);

  @override
  Result<void, AppError> validate(DoctorVisit entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.doctorName.trim().isEmpty) {
      return Failure(ValidationError('doctorName is required'));
    }
    if (entity.reason.trim().isEmpty) {
      return Failure(ValidationError('reason is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final nextVisit = await _repo.getNextUpcoming();
    if (nextVisit.isFailure) {
      return Failure(nextVisit.error!);
    }

    return Success(<String, dynamic>{
      'totalVisits': all.data!.length,
      'nextVisitDate': nextVisit.data?.visitDate.toIso8601String(),
    });
  }

  Future<Result<DoctorVisit?, AppError>> getNextUpcoming() => _repo.getNextUpcoming();

  Future<Result<void, AppError>> deleteWithAttachments(String id) async {
    final existing = await getById(id);
    if (existing.isFailure) {
      return Failure(existing.error!);
    }
    final deleteResult = await softDelete(id);
    if (deleteResult.isFailure) {
      return deleteResult;
    }
    final visit = existing.data;
    if (visit != null) {
      await _deleteAttachmentFiles(visit.attachmentPaths, context: '$serviceName.deleteWithAttachments');
    }
    return const Success(null);
  }

  Future<Result<void, AppError>> updateWithAttachmentCleanup(
    DoctorVisit previous,
    DoctorVisit updated,
  ) async {
    final updateResult = await update(updated);
    if (updateResult.isFailure) {
      return updateResult;
    }
    final removed = previous.attachmentPaths
        .where((path) => !updated.attachmentPaths.contains(path))
        .toList(growable: false);
    if (removed.isNotEmpty) {
      await _deleteAttachmentFiles(removed, context: '$serviceName.updateWithAttachmentCleanup');
    }
    return const Success(null);
  }

  Future<void> _deleteAttachmentFiles(List<String> paths, {required String context}) async {
    final deletion = await attachments.deleteAttachments(paths);
    if (deletion.isFailure) {
      logger.warning('[$context] record saved but some attachment files were left on disk: ${deletion.error}');
    }
  }
}
