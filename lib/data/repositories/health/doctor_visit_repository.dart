import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/health/doctor_visit.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class DoctorVisitRepository extends BaseRepository<DoctorVisit> {
  Future<Result<DoctorVisit?, AppError>> getNextUpcoming();
}

class DoctorVisitRepositoryImpl extends BaseRepositoryImpl<DoctorVisit>
    implements DoctorVisitRepository {
  DoctorVisitRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'doctor_visits';

  @override
  DoctorVisit fromJson(Map<String, dynamic> json) => DoctorVisit.fromJson(json);

  @override
  Future<Result<DoctorVisit?, AppError>> getNextUpcoming() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final now = DateTime.now();
    final upcoming = all.data!.where((visit) => visit.visitDate.isAfter(now)).toList()
      ..sort((a, b) => a.visitDate.compareTo(b.visitDate));

    return Success(upcoming.isEmpty ? null : upcoming.first);
  }
}
