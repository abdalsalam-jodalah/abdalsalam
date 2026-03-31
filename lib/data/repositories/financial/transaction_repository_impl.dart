import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../models/financial/transaction_model.dart';
import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final StorageGateway _storage;
  final LoggerService _logger;
  static const String _tableName = 'transactions';

  TransactionRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<TransactionModel, Error>> create(
    TransactionModel transaction,
  ) async {
    try {
      await _storage.upsertRecord(
        table: _tableName,
        id: transaction.id,
        record: transaction.toJson(),
        userId: transaction.userId,
      );
      _logger.info('Transaction created: ${transaction.id}');
      return Success(transaction);
    } catch (e, st) {
      _logger.error('Failed to create transaction', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<TransactionModel?, Error>> getById(String id) async {
    try {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) {
        return const Success(null);
      }
      return Success(TransactionModel.fromJson(record));
    } catch (e, st) {
      _logger.error('Failed to get transaction', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final transactions = records
          .map((r) => TransactionModel.fromJson(r))
          .where((t) => t.deletedAt == null)
          .toList();
      return Success(transactions);
    } catch (e, st) {
      _logger.error('Failed to get all transactions', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final filtered = allResult.data!
          .where((t) =>
              t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();

      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get transactions by date range', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByCategory(
    String categoryId,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final filtered = allResult.data!
          .where((t) => t.categoryId == categoryId)
          .toList();

      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get transactions by category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByType(
    TransactionType type,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final filtered = allResult.data!.where((t) => t.type == type).toList();

      return Success(filtered);
    } catch (e, st) {
      _logger.error('Failed to get transactions by type', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> update(TransactionModel transaction) async {
    try {
      final updated = transaction.copyWith(updatedAt: DateTime.now());
      await _storage.upsertRecord(
        table: _tableName,
        id: updated.id,
        record: updated.toJson(),
        userId: updated.userId,
      );
      _logger.info('Transaction updated: ${transaction.id}');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to update transaction', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    try {
      await _storage.deleteRecord(table: _tableName, id: id);
      _logger.info('Transaction deleted: $id');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete transaction', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<double, Error>> getTotalByType(
    TransactionType type,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactionsResult = await getByDateRange(start, end);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      final total = transactionsResult.data!
          .where((t) => t.type == type)
          .fold<double>(0, (sum, t) => sum + t.amount);

      return Success(total);
    } catch (e, st) {
      _logger.error('Failed to get total by type', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<Map<String, double>, Error>> getTotalByCategory(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactionsResult = await getByDateRange(start, end);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      final totals = <String, double>{};
      for (final transaction in transactionsResult.data!) {
        totals[transaction.categoryId] =
            (totals[transaction.categoryId] ?? 0) + transaction.amount;
      }

      return Success(totals);
    } catch (e, st) {
      _logger.error('Failed to get total by category', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getRecent(
    int limit,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) {
        return Failure(allResult.error!);
      }

      final sorted = allResult.data!..sort((a, b) => b.date.compareTo(a.date));
      final recent = sorted.take(limit).toList();

      return Success(recent);
    } catch (e, st) {
      _logger.error('Failed to get recent transactions', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
