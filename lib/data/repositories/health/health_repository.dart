import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/health/medication.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class HealthRepository extends BaseRepository<Medication> {
  Future<Result<List<Medication>, AppError>> activeOn(DateTime date);
}

class HealthRepositoryImpl extends BaseRepositoryImpl<Medication>
    implements HealthRepository {
  HealthRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'medications';

  @override
  Medication fromJson(Map<String, dynamic> json) => Medication.fromJson(json);

  @override
  Future<Result<List<Medication>, AppError>> activeOn(DateTime date) async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!.where((med) {
      final afterStart = !date.isBefore(med.startDate);
      final beforeEnd = med.endDate == null || !date.isAfter(med.endDate!);
      return afterStart && beforeEnd;
    }).toList(growable: false);

    return Success(rows);
  }
}
