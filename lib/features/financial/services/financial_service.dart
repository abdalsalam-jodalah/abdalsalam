import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
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
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'conversion_result.dart';
import 'currency_conversion_service.dart';
import 'financial_activity_logger.dart';

class FinancialService {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BudgetRepository _budgetRepo;
  final AccountRepository _accountRepo;
  final CurrencyConversionService _conversionService;
  final FinancialActivityLogger _activityLogger;
  final LoggerService _logger;
  final ErrorHandler _errorHandler;

  FinancialService({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BudgetRepository budgetRepo,
    required AccountRepository accountRepo,
    required FinancialActivityLogRepository activityLogRepo,
    required CurrencyConversionService conversionService,
    required LoggerService logger,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _budgetRepo = budgetRepo,
        _accountRepo = accountRepo,
        _conversionService = conversionService,
        _logger = logger,
        _errorHandler = ErrorHandler(logger),
        _activityLogger = FinancialActivityLogger(activityLogRepo, logger);

  // Transaction methods

  Future<Result<TransactionModel, AppError>> createTransaction(
    TransactionModel transaction,
  ) async {
    final result = await _transactionRepo.create(transaction);
    if (result.isSuccess) {
      final conversion = await _conversionForLog(transaction);
      await _activityLogger.logTransactionCreated(transaction, conversion: conversion);
    }
    return result;
  }

  Future<Result<void, AppError>> updateTransaction(TransactionModel transaction) async {
    final result = await _transactionRepo.update(transaction);
    if (result.isSuccess) {
      final conversion = await _conversionForLog(transaction);
      await _activityLogger.logTransactionUpdated(transaction, conversion: conversion);
    }
    return result;
  }

  Future<Result<void, AppError>> deleteTransaction(String id) async {
    final existingResult = await _transactionRepo.getById(id);
    if (existingResult.isFailure) {
      _logger.warning('Could not load transaction $id before delete; its deletion will not be audited: '
          '${existingResult.error}');
    }
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
    final conversionResult = await _conversionService.convertToBase(
      amount: transaction.amount,
      fromCurrency: transaction.currency,
      asOfDate: transaction.date,
    );
    if (conversionResult.isFailure) {
      _logger.warning('Transaction ${transaction.id} will be audited without a conversion rate: '
          '${conversionResult.error}');
    }
    return conversionResult.data;
  }

  Future<Result<double, AppError>> _amountInBase(TransactionModel transaction) async {
    final conversionResult = await _conversionService.convertToBase(
      amount: transaction.amount,
      fromCurrency: transaction.currency,
      asOfDate: transaction.date,
    );
    return conversionResult.map((conversion) => conversion.convertedAmount);
  }

  Failure<T, AppError> _mapCaughtError<T>(Object error, StackTrace stackTrace, String context) {
    return Failure(_errorHandler.mapException(error, context: context, stackTrace: stackTrace));
  }

  Future<Result<List<TransactionModel>, AppError>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _transactionRepo.getByDateRange(start, end);
  }

  Future<Result<List<TransactionModel>, AppError>> getRecentTransactions(
    int limit,
  ) async {
    return await _transactionRepo.getRecent(limit);
  }

  // Financial statistics — every sum below is currency-conversion-aware so
  // transactions recorded in different currencies never get silently mixed.

  Future<Result<Map<String, double>, AppError>> getFinancialSummary(
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
        final convertedResult = await _amountInBase(t);
        if (convertedResult.isFailure) {
          return Failure(convertedResult.error!);
        }
        if (t.type == TransactionType.income) {
          income += convertedResult.data!;
        } else {
          expense += convertedResult.data!;
        }
      }

      return Success({
        'income': income,
        'expense': expense,
        'balance': income - expense,
      });
    } catch (error, stackTrace) {
      return _mapCaughtError(error, stackTrace, 'FinancialService.getFinancialSummary');
    }
  }

  Future<Result<Map<String, double>, AppError>> getCategoryTotals(
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
        final convertedResult = await _amountInBase(t);
        if (convertedResult.isFailure) {
          return Failure(convertedResult.error!);
        }
        totals[t.categoryId] = (totals[t.categoryId] ?? 0) + convertedResult.data!;
      }

      return Success(totals);
    } catch (error, stackTrace) {
      return _mapCaughtError(error, stackTrace, 'FinancialService.getCategoryTotals');
    }
  }

  // Budget methods

  Future<Result<List<BudgetModel>, AppError>> getActiveBudgets() async {
    return await _budgetRepo.getActive();
  }

  Future<Result<BudgetModel, AppError>> createBudget(BudgetModel budget) async {
    final result = await _budgetRepo.create(budget);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, AppError>> updateBudget(BudgetModel budget) async {
    final result = await _budgetRepo.update(budget);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, AppError>> deleteBudget(BudgetModel budget) async {
    final result = await _budgetRepo.delete(budget.id);
    if (result.isSuccess) {
      await _activityLogger.logBudget(budget, FinancialActionType.deleted);
    }
    return result;
  }

  /// Spend is filtered to [budget.categoryId] and converted to base currency
  /// before summing — fixes the previous bug where progress reflected total
  /// household spending instead of this budget's category.
  Future<Result<Map<String, dynamic>, AppError>> getBudgetProgress(
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
        final convertedResult = await _amountInBase(t);
        if (convertedResult.isFailure) {
          return Failure(convertedResult.error!);
        }
        spent += convertedResult.data!;
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
    } catch (error, stackTrace) {
      return _mapCaughtError(error, stackTrace, 'FinancialService.getBudgetProgress');
    }
  }

  // Category methods

  Future<Result<List<CategoryModel>, AppError>> getAllCategories() async {
    return await _categoryRepo.getAll();
  }

  Future<Result<List<CategoryModel>, AppError>> getCategoriesByType(
    CategoryType type,
  ) async {
    return await _categoryRepo.getByType(type);
  }

  Future<Result<CategoryModel, AppError>> createCategory(CategoryModel category) async {
    final result = await _categoryRepo.create(category);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, AppError>> updateCategory(CategoryModel category) async {
    final result = await _categoryRepo.update(category);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, AppError>> deleteCategory(CategoryModel category) async {
    final result = await _categoryRepo.delete(category.id);
    if (result.isSuccess) {
      await _activityLogger.logCategory(category, FinancialActionType.deleted);
    }
    return result;
  }

  // Account methods

  Future<Result<List<AccountModel>, AppError>> getAllAccounts() async {
    return await _accountRepo.getAll();
  }

  Future<Result<List<AccountModel>, AppError>> getActiveAccounts() async {
    return await _accountRepo.getActive();
  }

  Future<Result<AccountModel, AppError>> createAccount(AccountModel account) async {
    final result = await _accountRepo.create(account);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.created);
    }
    return result;
  }

  Future<Result<void, AppError>> updateAccount(AccountModel account) async {
    final result = await _accountRepo.update(account);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.updated);
    }
    return result;
  }

  Future<Result<void, AppError>> deleteAccount(AccountModel account) async {
    final result = await _accountRepo.delete(account.id);
    if (result.isSuccess) {
      await _activityLogger.logAccount(account, FinancialActionType.deleted);
    }
    return result;
  }

  /// Current balance = initial balance + all of the account's transactions,
  /// each converted into the account's own currency. Derived on read rather
  /// than stored, so edits/deletes to transactions can never cause drift.
  Future<Result<double, AppError>> getAccountBalance(AccountModel account) async {
    try {
      final transactionsResult = await _transactionRepo.getByAccount(account.id);
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }

      double balance = account.initialBalance;
      for (final t in transactionsResult.data!) {
        final convertedResult = await _conversionService.convertToAccountCurrency(
          amount: t.amount,
          fromCurrency: t.currency,
          toCurrency: account.currency,
          asOfDate: t.date,
        );
        if (convertedResult.isFailure) {
          return Failure(convertedResult.error!);
        }
        final converted = convertedResult.data!.convertedAmount;
        balance += t.type == TransactionType.income ? converted : -converted;
      }

      return Success(balance);
    } catch (error, stackTrace) {
      return _mapCaughtError(error, stackTrace, 'FinancialService.getAccountBalance');
    }
  }

  /// One-stop net summary for the dashboard: net worth across all active
  /// accounts (converted to base currency), how many active budgets are
  /// near/over their limit, and the next few upcoming recurring transactions.
  Future<Result<Map<String, dynamic>, AppError>> getNetWorthSummary() async {
    try {
      final accountsResult = await _accountRepo.getActive();
      if (accountsResult.isFailure) {
        return Failure(accountsResult.error!);
      }

      double netWorthBase = 0;
      for (final account in accountsResult.data!) {
        final balanceResult = await getAccountBalance(account);
        if (balanceResult.isFailure) {
          return Failure(balanceResult.error!);
        }
        final convertedResult = await _conversionService.convertToBase(
          amount: balanceResult.data!,
          fromCurrency: account.currency,
          asOfDate: DateTime.now(),
        );
        if (convertedResult.isFailure) {
          return Failure(convertedResult.error!);
        }
        netWorthBase += convertedResult.data!.convertedAmount;
      }

      final budgetsResult = await _budgetRepo.getActive();
      if (budgetsResult.isFailure) {
        return Failure(budgetsResult.error!);
      }
      var budgetsOverThreshold = 0;
      final activeBudgets = budgetsResult.data!;
      for (final budget in activeBudgets) {
        final progressResult = await getBudgetProgress(budget);
        if (progressResult.isFailure) {
          _logger.warning('Budget ${budget.id} excluded from near-limit count: ${progressResult.error}');
          continue;
        }
        if (progressResult.data!['isNearLimit'] as bool? ?? false) {
          budgetsOverThreshold++;
        }
      }

      final transactionsResult = await _transactionRepo.getAll();
      if (transactionsResult.isFailure) {
        return Failure(transactionsResult.error!);
      }
      final upcomingRecurring = transactionsResult.data!
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
    } catch (error, stackTrace) {
      return _mapCaughtError(error, stackTrace, 'FinancialService.getNetWorthSummary');
    }
  }
}
