import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../data/repositories/financial/financial_activity_log_repository.dart';
import '../../../data/repositories/record_parser.dart';
import '../../../data/repositories/repository_operation_guard.dart';

class FinancialActivityLogRepositoryImpl implements FinancialActivityLogRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'financial_activity_log';

  FinancialActivityLogRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<FinancialActivityLogModel> get _parser => RecordParser<FinancialActivityLogModel>(
        table: _tableName,
        fromJson: FinancialActivityLogModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<FinancialActivityLogModel, AppError>> create(
    FinancialActivityLogModel entry,
  ) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: entry.id,
        record: entry.toJson(),
        userId: entry.userId,
      );
      return entry;
    });
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAllNewestFirst);
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getByEntityType(
    FinancialEntityType entityType,
  ) {
    return _guard.run('getByEntityType', () async {
      final entries = await _readAllNewestFirst();
      return entries.where((e) => e.entityType == entityType).toList();
    });
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getRecent(int limit) {
    return _guard.run('getRecent', () async {
      final entries = await _readAllNewestFirst();
      return entries.take(limit).toList();
    });
  }

  Future<List<FinancialActivityLogModel>> _readAllNewestFirst() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
