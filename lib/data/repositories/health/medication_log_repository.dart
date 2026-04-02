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
  Future<Result<List<MedicationLog>, AppError>> getByMedicationId(String medicationId) async {
    try {
      final result = await storage.query(
        table: tableName,
        filters: {'medicationId': medicationId},
      );
      final logs = result.map((json) => fromJson(json)).toList();
      logger.info('[$tableName] Found ${logs.length} logs for medication $medicationId');
      return Success(logs);
    } catch (e, st) {
      logger.error('[$tableName] getByMedicationId failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<MedicationLog>, AppError>> getByDate(DateTime date) async {
    try {
      final allLogs = await getAll();
      if (allLogs.isFailure) {
        return Failure(allLogs.error!);
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final filtered = allLogs.data!
          .where((log) =>
              !log.scheduledFor.isBefore(startOfDay) && log.scheduledFor.isBefore(endOfDay))
          .toList();

      filtered.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      logger.info('[$tableName] Found ${filtered.length} logs for date $date');
      return Success(filtered);
    } catch (e, st) {
      logger.error('[$tableName] getByDate failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<MedicationLog>, AppError>> getPendingForDate(DateTime date) async {
    try {
      final logsResult = await getByDate(date);
      if (logsResult.isFailure) {
        return Failure(logsResult.error!);
      }

      final pending = logsResult.data!.where((log) => log.isPending).toList();
      logger.info('[$tableName] Found ${pending.length} pending logs for date $date');
      return Success(pending);
    } catch (e, st) {
      logger.error('[$tableName] getPendingForDate failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<MedicationLog?, AppError>> getLogForMedicationAndTime(
    String medicationId,
    DateTime date,
    String time,
  ) async {
    try {
      final logsResult = await getByMedicationId(medicationId);
      if (logsResult.isFailure) {
        return Failure(logsResult.error!);
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      MedicationLog? log;
      try {
        log = logsResult.data!.firstWhere(
          (log) =>
              !log.scheduledFor.isBefore(startOfDay) &&
              log.scheduledFor.isBefore(endOfDay) &&
              log.scheduledTime == time,
        );
      } catch (e) {
        // No log found for this time
        log = null;
      }

      return Success(log);
    } catch (e, st) {
      logger.error('[$tableName] getLogForMedicationAndTime failed', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
