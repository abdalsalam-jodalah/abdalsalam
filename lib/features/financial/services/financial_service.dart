import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/financial/budget_repository.dart';
import '../../../data/repositories/financial/account_repository.dart';
import '../../../data/repositories/financial/financial_activity_log_repository.dart';
import 'currency_conversion_service.dart';
import 'financial_activity_logger.dart';

class FinancialService {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BudgetRepository _budgetRepo;
  final AccountRepository _accountRepo;
  final CurrencyConversionService _conversionService;
  final FinancialActivityLogger _activityLogger;

  FinancialService({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BudgetRepository budgetRepo,
    required AccountRepository accountRepo,
    required FinancialActivityLogRepository activityLogRepo,
    required CurrencyConversionService conversionService,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _budgetRepo = budgetRepo,
        _accountRepo = accountRepo,
        _conversionService = conversionService,
        _activityLogger = FinancialActivityLogger(activityLogRepo);

  // Transaction methods

  Future<Result<TransactionModel, Error>> createTransaction(
    TransactionModel transaction,
  ) async {
    final result = await _transactionRepo.create(transaction);
    if (result.isSuccess) {
      final conversion = await _conversionForLog(transaction);
      await _activityLogger.logTransactionCreated(transaction, conversion: conversion);
    }
    return result;
  }

  Future<Result<void, Error>> updateTransaction(TransactionModel transaction) async {
    final result = await _transactionRepo.update(transaction);
    if (result.isSuccess) {
      final conversion = await _conversionForLog(transaction);
      await _activityLogger.logTransactionUpdated(transaction, conversion: conversion);
    }
    return result;
  }

  Future<Result<void, Error>> deleteTransaction(String id) async {
    final existingResult = await _transactionRepo.getById(id);
    final result = await _transactionRepo.delete(id);
    if (result.isSuccess && existingResult.data != null) {
      await _activityLogger.logTransactionDeleted(existingResult.data!);
    }
    return result;
  }

  Future<ConversionResult?> _conversionForLog(TransactionModel transaction) async {
    if (transaction.currency == CurrencyConversionService.baseCurrencyCode) {
      return null;
    }
    return _conversionService.convertToBase(
      amount: transaction.amount,
      fromCurrency: transaction.currency,
      asOfDate: transaction.date,
    );
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

  // Financial statistics — every sum below is currency-conversion-aware so
  // transactions recorded in different currencies never get silently mixed.

  Future<Result<Map<String, double>, Error>> getFinancialSummary(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactionsResult = await _transactionRepo.getByDateRange(start, end);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      double income = 0;
      double expense = 0;
      for (final t in transactionsResult.data!) {
        final converted = await _conversionService.convertToBase(
          amount: t.amount,
          fromCurrency: t.currency,
          asOfDate: t.date,
        );
        if (t.type == TransactionType.income) {
          income += converted.convertedAmount;
        } else {
          expense += converted.convertedAmount;
        }
      }

      return Success({
        'income': income,
        'expense': expense,
        'balance': income - expense,
      });
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  Future<Result<Map<String, double>, Error>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final transactionsResult = await _transactionRepo.getByDateRange(start, end);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      final totals = <String, double>{};
      for (final t in transactionsResult.data!) {
        final converted = await _conversionService.convertToBase(
          amount: t.amount,
          fromCurrency: t.currency,
          asOfDate: t.date,
        );
        totals[t.categoryId] = (totals[t.categoryId] ?? 0) + converted.convertedAmount;
      }

      return Success(totals);
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  // Budget methods

  Future<Result<List<BudgetModel>, Error>> getActiveBudgets() async {
    return await _budgetRepo.getActive();
  }

  Future<Result<BudgetModel, Error>> createBudget(BudgetModel budget) async {
    final result = await _budgetRepo.create(budget);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, Error>> updateBudget(BudgetModel budget) async {
    final result = await _budgetRepo.update(budget);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, Error>> deleteBudget(BudgetModel budget) async {
    final result = await _budgetRepo.delete(budget.id);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.deleted);
    }
    return result;
  }

  /// Spend is filtered to [budget.categoryId] and converted to base currency
  /// before summing — fixes the previous bug where progress reflected total
  /// household spending instead of this budget's category.
  Future<Result<Map<String, dynamic>, Error>> getBudgetProgress(
    BudgetModel budget,
  ) async {
    try {
      final transactionsResult = await _transactionRepo.getByCategoryAndDateRange(
        budget.categoryId,
        budget.startDate,
        budget.endDate,
      );
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      double spent = 0;
      for (final t in transactionsResult.data!.where((t) => t.type == TransactionType.expense)) {
        final converted = await _conversionService.convertToBase(
          amount: t.amount,
          fromCurrency: t.currency,
          asOfDate: t.date,
        );
        spent += converted.convertedAmount;
      }

      final percentage = budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
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

  Future<Result<CategoryModel, Error>> createCategory(CategoryModel category) async {
    final result = await _categoryRepo.create(category);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, Error>> updateCategory(CategoryModel category) async {
    final result = await _categoryRepo.update(category);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, Error>> deleteCategory(CategoryModel category) async {
    final result = await _categoryRepo.delete(category.id);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.deleted);
    }
    return result;
  }

  // Account methods

  Future<Result<List<AccountModel>, Error>> getAllAccounts() async {
    return await _accountRepo.getAll();
  }

  Future<Result<List<AccountModel>, Error>> getActiveAccounts() async {
    return await _accountRepo.getActive();
  }

  Future<Result<AccountModel, Error>> createAccount(AccountModel account) async {
    final result = await _accountRepo.create(account);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, Error>> updateAccount(AccountModel account) async {
    final result = await _accountRepo.update(account);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, Error>> deleteAccount(AccountModel account) async {
    final result = await _accountRepo.delete(account.id);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.deleted);
    }
    return result;
  }

  /// Current balance = initial balance + all of the account's transactions,
  /// each converted into the account's own currency. Derived on read rather
  /// than stored, so edits/deletes to transactions can never cause drift.
  Future<Result<double, Error>> getAccountBalance(AccountModel account) async {
    try {
      final transactionsResult = await _transactionRepo.getByAccount(account.id);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      double balance = account.initialBalance;
      for (final t in transactionsResult.data!) {
        final converted = await _conversionService.convertToAccountCurrency(
          amount: t.amount,
          fromCurrency: t.currency,
          toCurrency: account.currency,
          asOfDate: t.date,
        );
        balance += t.type == TransactionType.income ? converted : -converted;
      }

      return Success(balance);
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }

  /// One-stop net summary for the dashboard: net worth across all active
  /// accounts (converted to base currency), how many active budgets are
  /// near/over their limit, and the next few upcoming recurring transactions.
  Future<Result<Map<String, dynamic>, Error>> getNetWorthSummary() async {
    try {
      final accountsResult = await _accountRepo.getActive();
      if (accountsResult.isFailure) {
        return Failure(accountsResult.error!);
      }

      double netWorthBase = 0;
      for (final account in accountsResult.data!) {
        final balanceResult = await getAccountBalance(account);
        if (balanceResult.isFailure) {
          continue;
        }
        final converted = await _conversionService.convertToBase(
          amount: balanceResult.data!,
          fromCurrency: account.currency,
          asOfDate: DateTime.now(),
        );
        netWorthBase += converted.convertedAmount;
      }

      final budgetsResult = await _budgetRepo.getActive();
      var budgetsOverThreshold = 0;
      final activeBudgets = budgetsResult.data ?? [];
      for (final budget in activeBudgets) {
        final progressResult = await getBudgetProgress(budget);
        if (progressResult.isSuccess &&
            (progressResult.data!['isNearLimit'] as bool? ?? false)) {
          budgetsOverThreshold++;
        }
      }

      final transactionsResult = await _transactionRepo.getAll();
      final upcomingRecurring = (transactionsResult.data ?? [])
          .where((t) => t.isRecurring && t.recurrenceNextDueDate != null)
          .toList()
        ..sort((a, b) => a.recurrenceNextDueDate!.compareTo(b.recurrenceNextDueDate!));

      return Success({
        'netWorth': netWorthBase,
        'accountCount': accountsResult.data!.length,
        'totalBudgets': activeBudgets.length,
        'budgetsNearOrOverLimit': budgetsOverThreshold,
        'upcomingRecurring': upcomingRecurring.take(5).toList(),
      });
    } catch (e) {
      return Failure(FinancialError(e.toString()));
    }
  }
}
