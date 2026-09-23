import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../models/financial/transaction_model.dart';
import '../record_parser.dart';
import '../repository_operation_guard.dart';
import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'transactions';

  TransactionRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<TransactionModel> get _parser => RecordParser<TransactionModel>(
        table: _tableName,
        fromJson: TransactionModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<TransactionModel, AppError>> create(
    TransactionModel transaction,
  ) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: transaction.id,
        record: transaction.toJson(),
        userId: transaction.userId,
      );
      _logger.info('Transaction created: ${transaction.id}');
      return transaction;
    });
  }

  @override
  Future<Result<TransactionModel?, AppError>> getById(String id) {
    return _guard.run('getById', () async {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return null;
      }
      return _parser.parseOne(record);
    });
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAll);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return _guard.run('getByDateRange', () => _readInDateRange(start, end));
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByCategory(
    String categoryId,
  ) {
    return _guard.run('getByCategory', () async {
      final transactions = await _readAll();
      return transactions.where((t) => t.categoryId == categoryId).toList();
    });
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) {
    return _guard.run('getByCategoryAndDateRange', () async {
      final transactions = await _readInDateRange(start, end);
      return transactions.where((t) => t.categoryId == categoryId).toList();
    });
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByAccount(
    String accountId,
  ) {
    return _guard.run('getByAccount', () async {
      final transactions = await _readAll();
      return transactions.where((t) => t.accountId == accountId).toList();
    });
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByType(
    TransactionType type,
  ) {
    return _guard.run('getByType', () async {
      final transactions = await _readAll();
      return transactions.where((t) => t.type == type).toList();
    });
  }

  @override
  Future<Result<void, AppError>> update(TransactionModel transaction) {
    return _guard.run('update', () async {
      final updated = transaction.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Transaction updated: ${transaction.id}');
    });
  }

  @override
  Future<Result<void, AppError>> delete(String id) {
    return _guard.run('delete', () async {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Transaction deleted: $id');
    });
  }

  @override
  Future<Result<double, AppError>> getTotalByType(
    TransactionType type,
    DateTime start,
    DateTime end,
  ) {
    return _guard.run('getTotalByType', () async {
      final transactions = await _readInDateRange(start, end);
      return transactions
          .where((t) => t.type == type)
          .fold<double>(0, (sum, t) => sum + t.amount);
    });
  }

  @override
  Future<Result<Map<String, double>, AppError>> getTotalByCategory(
    DateTime start,
    DateTime end,
  ) {
    return _guard.run('getTotalByCategory', () async {
      final totals = <String, double>{};
      for (final transaction in await _readInDateRange(start, end)) {
        totals[transaction.categoryId] =
            (totals[transaction.categoryId] ?? 0) + transaction.amount;
      }
      return totals;
    });
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getRecent(
    int limit,
  ) {
    return _guard.run('getRecent', () async {
      final sorted = (await _readAll())..sort((a, b) => b.date.compareTo(a.date));
      return sorted.take(limit).toList();
    });
  }

  Future<List<TransactionModel>> _readAll() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records).where((t) => t.deletedAt == null).toList();
  }

  Future<List<TransactionModel>> _readInDateRange(DateTime start, DateTime end) async {
    final transactions = await _readAll();
    return transactions
        .where((t) =>
            t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }
}
