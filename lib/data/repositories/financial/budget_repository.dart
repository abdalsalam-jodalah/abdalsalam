import '../../../core/result/result.dart';
import '../../models/financial/budget_model.dart';

abstract class BudgetRepository {
  Future<Result<BudgetModel, Error>> create(BudgetModel budget);
  Future<Result<BudgetModel?, Error>> getById(String id);
  Future<Result<List<BudgetModel>, Error>> getAll();
  Future<Result<List<BudgetModel>, Error>> getActive();
  Future<Result<List<BudgetModel>, Error>> getByPeriod(BudgetPeriod period);
  Future<Result<void, Error>> update(BudgetModel budget);
  Future<Result<void, Error>> delete(String id);
}
