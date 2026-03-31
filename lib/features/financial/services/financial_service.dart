import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/financial/budget_repository.dart';

class FinancialService {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BudgetRepository _budgetRepo;

  FinancialService({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BudgetRepository budgetRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _budgetRepo = budgetRepo;

  // Transaction methods
  Future<Result<TransactionModel, Error>> createTransaction(
    TransactionModel transaction,
  ) async {
    return await _transactionRepo.create(transaction);
  }

  Future<Result<List<TransactionModel>, Error>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _transactionRepo.getByDateRange(start, end);
  }

  Future<Result<List<TransactionModel>, Error>> getRecentTransactions(
    int limit,
  ) async {
    return await _transactionRepo.getRecent(limit);
  }

  // Financial statistics
  Future<Result<Map<String, double>, Error>> getFinancialSummary(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final incomeResult = await _transactionRepo.getTotalByType(
        TransactionType.income,
        start,
        end,
      );
      final expenseResult = await _transactionRepo.getTotalByType(
        TransactionType.expense,
        start,
        end,
      );

      if (incomeResult.isFailure) return Failure(incomeResult.error!);
      if (expenseResult.isFailure) return Failure(expenseResult.error!);

      return Success({
        'income': incomeResult.data!,
        'expense': expenseResult.data!,
        'balance': incomeResult.data! - expenseResult.data!,
      });
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  Future<Result<Map<String, double>, Error>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    return await _transactionRepo.getTotalByCategory(start, end);
  }

  // Budget methods
  Future<Result<List<BudgetModel>, Error>> getActiveBudgets() async {
    return await _budgetRepo.getActive();
  }

  Future<Result<Map<String, dynamic>, Error>> getBudgetProgress(
    BudgetModel budget,
  ) async {
    try {
      final spentResult = await _transactionRepo.getTotalByType(
        TransactionType.expense,
        budget.startDate,
        budget.endDate,
      );

      if (spentResult.isFailure) {
        return Failure(spentResult.error!);
      }

      final spent = spentResult.data!;
      final percentage = (spent / budget.amount) * 100;
      final remaining = budget.amount - spent;

      return Success({
        'budget': budget,
        'spent': spent,
        'remaining': remaining,
        'percentage': percentage,
        'isOverBudget': spent > budget.amount,
        'isNearLimit': percentage >= budget.alertThreshold,
      });
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  // Category methods
  Future<Result<List<CategoryModel>, Error>> getAllCategories() async {
    return await _categoryRepo.getAll();
  }

  Future<Result<List<CategoryModel>, Error>> getCategoriesByType(
    CategoryType type,
  ) async {
    return await _categoryRepo.getByType(type);
  }
}
