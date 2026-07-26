import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/health/blood_test.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class BloodTestRepository extends BaseRepository<BloodTest> {
  Future<Result<List<BloodTest>, AppError>> getUpcoming();
  Future<Result<List<BloodTest>, AppError>> getCompleted();
}

class BloodTestRepositoryImpl extends BaseRepositoryImpl<BloodTest>
    implements BloodTestRepository {
  BloodTestRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'blood_tests';

  @override
  BloodTest fromJson(Map<String, dynamic> json) => BloodTest.fromJson(json);

  @override
  Future<Result<List<BloodTest>, AppError>> getUpcoming() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!.where((test) => test.completedDate == null).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return Success(rows);
  }

  @override
  Future<Result<List<BloodTest>, AppError>> getCompleted() async {
    final all = await getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    final rows = all.data!.where((test) => test.completedDate != null).toList()
      ..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));
    return Success(rows);
  }
}
