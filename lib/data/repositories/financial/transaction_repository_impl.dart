import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../models/financial/transaction_model.dart';
import 'transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  // Mock in-memory storage
  final Map<String, TransactionModel> _storage = {};

  @override
  Future<Result<TransactionModel, Error>> create(
    TransactionModel transaction,
  ) async {
    try {
      _storage[transaction.id] = transaction;
      return Success(transaction);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<TransactionModel?, Error>> getById(String id) async {
    try {
      final transaction = _storage[id];
      return Success(transaction);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getAll() async {
    try {
      final results = _storage.values.toList();
      return Success(results);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final results = _storage.values
          .where((t) => t.date.isAfter(start) && t.date.isBefore(end))
          .toList();
      return Success(results);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByCategory(
    String categoryId,
  ) async {
    try {
      final results = _storage.values
          .where((t) => t.categoryId == categoryId)
          .toList();
      return Success(results);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByType(
    TransactionType type,
  ) async {
    try {
      final results = _storage.values.where((t) => t.type == type).toList();
      return Success(results);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> update(TransactionModel transaction) async {
    try {
      _storage[transaction.id] = transaction;
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    try {
      _storage.remove(id);
      return const Success(null);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
