import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/budget_model.dart';

abstract class BudgetRepository {
  Future<Result<BudgetModel, AppError>> create(BudgetModel budget);
  Future<Result<BudgetModel?, AppError>> getById(String id);
  Future<Result<List<BudgetModel>, AppError>> getAll();
  Future<Result<List<BudgetModel>, AppError>> getActive();
  Future<Result<List<BudgetModel>, AppError>> getByPeriod(BudgetPeriod period);
  Future<Result<void, AppError>> update(BudgetModel budget);
  Future<Result<void, AppError>> delete(String id);
}
