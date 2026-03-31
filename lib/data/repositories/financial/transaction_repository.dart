import '../../../core/result/result.dart';
import '../../models/financial/transaction_model.dart';

abstract class TransactionRepository {
  Future<Result<TransactionModel, Error>> create(TransactionModel transaction);
  Future<Result<TransactionModel?, Error>> getById(String id);
  Future<Result<List<TransactionModel>, Error>> getAll();
  Future<Result<List<TransactionModel>, Error>> getByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Result<List<TransactionModel>, Error>> getByCategory(
    String categoryId,
  );
  Future<Result<List<TransactionModel>, Error>> getByType(
    TransactionType type,
  );
  Future<Result<void, Error>> update(TransactionModel transaction);
  Future<Result<void, Error>> delete(String id);
  Future<Result<double, Error>> getTotalByType(
    TransactionType type,
    DateTime start,
    DateTime end,
  );
  Future<Result<Map<String, double>, Error>> getTotalByCategory(
    DateTime start,
    DateTime end,
  );
  Future<Result<List<TransactionModel>, Error>> getRecent(int limit);
}
