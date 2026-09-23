import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/transaction_model.dart';

abstract class TransactionRepository {
  Future<Result<TransactionModel, AppError>> create(TransactionModel transaction);
  Future<Result<TransactionModel?, AppError>> getById(String id);
  Future<Result<List<TransactionModel>, AppError>> getAll();
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  );
  Future<Result<List<TransactionModel>, AppError>> getByCategory(
    String categoryId,
  );
  Future<Result<List<TransactionModel>, AppError>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  );
  Future<Result<List<TransactionModel>, AppError>> getByAccount(
    String accountId,
  );
  Future<Result<List<TransactionModel>, AppError>> getByType(
    TransactionType type,
  );
  Future<Result<void, AppError>> update(TransactionModel transaction);
  Future<Result<void, AppError>> delete(String id);
  Future<Result<double, AppError>> getTotalByType(
    TransactionType type,
    DateTime start,
    DateTime end,
  );
  Future<Result<Map<String, double>, AppError>> getTotalByCategory(
    DateTime start,
    DateTime end,
  );
  Future<Result<List<TransactionModel>, AppError>> getRecent(int limit);
}
