import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/health/medication_log.dart';
import '../base_repository.dart';
import '../base_repository_impl.dart';

abstract class MedicationLogRepository extends BaseRepository<MedicationLog> {
  Future<Result<List<MedicationLog>, AppError>> getByMedicationId(String medicationId);
  Future<Result<List<MedicationLog>, AppError>> getByDate(DateTime date);
  Future<Result<List<MedicationLog>, AppError>> getPendingForDate(DateTime date);
  Future<Result<MedicationLog?, AppError>> getLogForMedicationAndTime(
    String medicationId,
    DateTime date,
    String time,
  );
}

class MedicationLogRepositoryImpl extends BaseRepositoryImpl<MedicationLog>
    implements MedicationLogRepository {
  MedicationLogRepositoryImpl(super.storage, super.logger);

  @override
  String get tableName => 'medication_logs';

  @override
  MedicationLog fromJson(Map<String, dynamic> json) => MedicationLog.fromJson(json);

  @override
  Future<Result<List<MedicationLog>, AppError>> getByMedicationId(String medicationId) {
    return guardStorage('getByMedicationId', () async {
      final rows = await storage.query(
        table: tableName,
        filters: {'medicationId': medicationId},
      );
      final logs = parseRecords(rows);
      logger.info('[$tableName] Found ${logs.length} logs for medication $medicationId');
      return logs;
    });
  }

  @override
  Future<Result<List<MedicationLog>, AppError>> getByDate(DateTime date) async {
    final allLogs = await getAll();
    if (allLogs.isFailure) {
      return Failure(allLogs.error!);
    }

    final filtered = allLogs.data!.where((log) => _isScheduledOnDay(log, date)).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    logger.info('[$tableName] Found ${filtered.length} logs for date $date');
    return Success(filtered);
  }

  @override
  Future<Result<List<MedicationLog>, AppError>> getPendingForDate(DateTime date) async {
    final logsResult = await getByDate(date);
    if (logsResult.isFailure) {
      return Failure(logsResult.error!);
    }

    final pending = logsResult.data!.where((log) => log.isPending).toList();
    logger.info('[$tableName] Found ${pending.length} pending logs for date $date');
    return Success(pending);
  }

  @override
  Future<Result<MedicationLog?, AppError>> getLogForMedicationAndTime(
    String medicationId,
    DateTime date,
    String time,
  ) async {
    final logsResult = await getByMedicationId(medicationId);
    if (logsResult.isFailure) {
      return Failure(logsResult.error!);
    }

    final match = logsResult.data!
        .where((log) => _isScheduledOnDay(log, date) && log.scheduledTime == time)
        .firstOrNull;
    return Success(match);
  }

  bool _isScheduledOnDay(MedicationLog log, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return !log.scheduledFor.isBefore(startOfDay) && log.scheduledFor.isBefore(endOfDay);
  }
}
