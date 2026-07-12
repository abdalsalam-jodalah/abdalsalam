import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/religious/athkar_content.dart';
import '../../models/religious/athkar_log.dart';
import '../base_repository_impl.dart';

class AthkarLogRepository extends BaseRepositoryImpl<AthkarLog> {
  AthkarLogRepository(super.storage, super.logger);

  @override
  String get tableName => 'athkar_logs';

  @override
  AthkarLog fromJson(Map<String, dynamic> json) {
    return AthkarLog.fromJson(json);
  }

  Future<Result<List<AthkarLog>, AppError>> getByCategory(AthkarCategory category) {
    return query(<String, dynamic>{'category': category.name});
  }

  Future<Result<List<AthkarLog>, AppError>> getTodayForCategory(AthkarCategory category) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await getByDateRange(startOfDay, endOfDay);
    if (result.isFailure) {
      return Failure(result.error!);
    }
    final filtered = result.data!.where((log) => log.category == category).toList();
    return Success(filtered);
  }
}
