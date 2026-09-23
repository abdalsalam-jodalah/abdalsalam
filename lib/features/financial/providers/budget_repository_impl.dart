import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/repositories/financial/budget_repository.dart';
import '../../../data/repositories/record_parser.dart';
import '../../../data/repositories/repository_operation_guard.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'budgets';

  BudgetRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<BudgetModel> get _parser => RecordParser<BudgetModel>(
        table: _tableName,
        fromJson: BudgetModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<BudgetModel, AppError>> create(BudgetModel budget) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: budget.id,
        record: budget.toJson(),
        userId: budget.userId,
      );
      _logger.info('Budget created: ${budget.id}');
      return budget;
    });
  }

  @override
  Future<Result<BudgetModel?, AppError>> getById(String id) {
    return _guard.run('getById', () async {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return null;
      }
      return _parser.parseOne(record);
    });
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAll);
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getActive() {
    return _guard.run('getActive', () async {
      final budgets = await _readAll();
      final now = DateTime.now();
      return budgets
          .where((b) =>
              b.isActive &&
              b.startDate.isBefore(now) &&
              b.endDate.isAfter(now))
          .toList();
    });
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getByPeriod(BudgetPeriod period) {
    return _guard.run('getByPeriod', () async {
      final budgets = await _readAll();
      return budgets.where((b) => b.period == period).toList();
    });
  }

  @override
  Future<Result<void, AppError>> update(BudgetModel budget) {
    return _guard.run('update', () async {
      final updated = budget.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Budget updated: ${budget.id}');
    });
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    return _guard.run('delete', () async {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Budget deleted: $id');
    });
  }

  Future<List<BudgetModel>> _readAll() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records).where((b) => b.deletedAt == null).toList();
  }
}
