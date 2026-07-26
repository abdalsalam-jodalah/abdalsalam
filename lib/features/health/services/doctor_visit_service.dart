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

    return Success(<String, dynamic>{
      'totalVisits': all.data!.length,
      'nextVisitDate': nextVisit.data?.visitDate.toIso8601String(),
    });
  }

  Future<Result<DoctorVisit?, AppError>> getNextUpcoming() => _repo.getNextUpcoming();

  /// Deletes the visit's local attachment files, then soft-deletes the record.
  Future<Result<void, AppError>> deleteWithAttachments(String id) async {
    final existing = await getById(id);
    if (existing.isSuccess && existing.data != null) {
      await attachments.deleteAttachments(existing.data!.attachmentPaths);
    }
    return softDelete(id);
  }

  /// Removes any attachment files that are no longer referenced by [updated]
  /// compared to what was previously stored, then saves.
  Future<Result<void, AppError>> updateWithAttachmentCleanup(
    DoctorVisit previous,
    DoctorVisit updated,
  ) async {
    final removed = previous.attachmentPaths
        .where((path) => !updated.attachmentPaths.contains(path))
        .toList(growable: false);
    if (removed.isNotEmpty) {
      await attachments.deleteAttachments(removed);
    }
    return update(updated);
  }
}
