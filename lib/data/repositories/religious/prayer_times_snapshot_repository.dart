import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/religious/prayer_times_snapshot.dart';
import '../base_repository_impl.dart';

class PrayerTimesSnapshotRepository extends BaseRepositoryImpl<PrayerTimesSnapshot> {
  PrayerTimesSnapshotRepository(super.storage, super.logger);

  @override
  String get tableName => 'prayer_times_snapshots';

  @override
  PrayerTimesSnapshot fromJson(Map<String, dynamic> json) {
    return PrayerTimesSnapshot.fromJson(json);
  }

  Future<Result<PrayerTimesSnapshot?, AppError>> getByDateKey(String dateKey) async {
    final result = await query(<String, dynamic>{'dateKey': dateKey});
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final data = result.data!;
    if (data.isEmpty) {
      return const Success(null);
    }
    return Success(data.first);
  }
}
