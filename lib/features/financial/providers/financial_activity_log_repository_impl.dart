import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../data/repositories/financial/financial_activity_log_repository.dart';

class FinancialActivityLogRepositoryImpl implements FinancialActivityLogRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'financial_activity_log';

  FinancialActivityLogRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<FinancialActivityLogModel, Error>> create(
    FinancialActivityLogModel entry,
  ) async {
    try {
      await _storage.upsertRecord(
        table: _tableName,
        id: entry.id,
        record: entry.toJson(),
        userId: entry.userId,
      );
      return Success(entry);
    } catch (e, st) {
      _logger.error('Failed to create activity log entry', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final entries = records.map(FinancialActivityLogModel.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success(entries);
    } catch (e, st) {
      _logger.error('Failed to get activity log', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getByEntityType(
    FinancialEntityType entityType,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }
      final filtered =
          allResult.data!.where((e) => e.entityType == entityType).toList();
      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get activity log by entity type', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getRecent(int limit) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }
      return Success(allResult.data!.take(limit).toList());
    } catch (e, st) {
      _logger.error('Failed to get recent activity log', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
