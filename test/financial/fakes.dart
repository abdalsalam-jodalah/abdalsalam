import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/account_repository.dart';
import 'package:abdalsalam/data/repositories/financial/budget_repository.dart';
import 'package:abdalsalam/data/repositories/financial/category_repository.dart';
import 'package:abdalsalam/data/repositories/financial/exchange_rate_repository.dart';
import 'package:abdalsalam/data/repositories/financial/financial_activity_log_repository.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> transactions;

  FakeTransactionRepository([List<TransactionModel>? seed]) : transactions = seed ?? [];

  @override
  Future<Result<TransactionModel, AppError>> create(TransactionModel transaction) async {
    transactions.add(transaction);
    return Success(transaction);
  }

  @override
  Future<Result<void, AppError>> update(TransactionModel transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) transactions[index] = transaction;
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    transactions.removeWhere((t) => t.id == id);
    return const Success(null);
  }

  @override
  Future<Result<TransactionModel?, AppError>> getById(String id) async {
    try {
      return Success(transactions.firstWhere((t) => t.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getAll() async => Success(List.of(transactions));

  @override
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return Success(transactions
        .where((t) =>
            !t.date.isBefore(start.subtract(const Duration(seconds: 1))) &&
            !t.date.isAfter(end.add(const Duration(seconds: 1))))
        .toList());
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByCategory(String categoryId) async {
    return Success(transactions.where((t) => t.categoryId == categoryId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final dateRangeResult = await getByDateRange(start, end);
    return Success(dateRangeResult.data!.where((t) => t.categoryId == categoryId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByAccount(String accountId) async {
    return Success(transactions.where((t) => t.accountId == accountId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByType(TransactionType type) async {
    return Success(transactions.where((t) => t.type == type).toList());
  }

  @override
  Future<Result<double, AppError>> getTotalByType(
    TransactionType type,
    DateTime start,
    DateTime end,
  ) async {
    final rangeResult = await getByDateRange(start, end);
    final total = rangeResult.data!
        .where((t) => t.type == type)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return Success(total);
  }

  @override
  Future<Result<Map<String, double>, AppError>> getTotalByCategory(
    DateTime start,
    DateTime end,
  ) async {
    final rangeResult = await getByDateRange(start, end);
    final totals = <String, double>{};
    for (final t in rangeResult.data!) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    return Success(totals);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getRecent(int limit) async {
    final sorted = List.of(transactions)..sort((a, b) => b.date.compareTo(a.date));
    return Success(sorted.take(limit).toList());
  }
}

class FakeExchangeRateRepository implements ExchangeRateRepository {
  final List<ExchangeRateModel> rates;

  FakeExchangeRateRepository([List<ExchangeRateModel>? seed]) : rates = seed ?? [];

  @override
  Future<Result<ExchangeRateModel, AppError>> create(ExchangeRateModel rate) async {
    rates.add(rate);
    return Success(rate);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getById(String id) async {
    try {
      return Success(rates.firstWhere((r) => r.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getAll() async => Success(List.of(rates));

  @override
  Future<Result<ExchangeRateModel?, AppError>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    final matches = rates
        .where((r) => r.fromCurrency == fromCurrency && r.toCurrency == toCurrency)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Success(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final matches = rates.where((r) =>
        r.fromCurrency == fromCurrency &&
        r.toCurrency == toCurrency &&
        DateTime(r.date.year, r.date.month, r.date.day) == targetDate);
    return Success(matches.isEmpty ? null : matches.first);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getNearestRateOnOrBefore(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final candidates = rates
        .where((r) =>
            r.fromCurrency == fromCurrency &&
            r.toCurrency == toCurrency &&
            !r.date.isAfter(endOfDay))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return Success(candidates.isEmpty ? null : candidates.first);
  }

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  ) async {
    return Success(rates
        .where((r) =>
            r.fromCurrency == fromCurrency &&
            r.toCurrency == toCurrency &&
            !r.date.isBefore(start) &&
            !r.date.isAfter(end))
        .toList());
  }

  @override
  Future<Result<void, AppError>> deleteOldRates(DateTime before) async {
    rates.removeWhere((r) => r.date.isBefore(before));
    return const Success(null);
  }
}

class FakeFinancialActivityLogRepository implements FinancialActivityLogRepository {
  final List<FinancialActivityLogModel> entries = [];

  @override
  Future<Result<FinancialActivityLogModel, AppError>> create(
    FinancialActivityLogModel entry,
  ) async {
    entries.add(entry);
    return Success(entry);
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getAll() async =>
      Success(List.of(entries));

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getByEntityType(
    FinancialEntityType entityType,
  ) async {
    return Success(entries.where((e) => e.entityType == entityType).toList());
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getRecent(int limit) async {
    return Success(entries.take(limit).toList());
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> categories = [];

  @override
  Future<Result<CategoryModel, AppError>> create(CategoryModel category) async {
    categories.add(category);
    return Success(category);
  }

  @override
  Future<Result<void, AppError>> update(CategoryModel category) async {
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) categories[index] = category;
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    categories.removeWhere((c) => c.id == id);
    return const Success(null);
  }

  @override
  Future<Result<CategoryModel?, AppError>> getById(String id) async {
    try {
      return Success(categories.firstWhere((c) => c.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<CategoryModel>, AppError>> getAll() async => Success(List.of(categories));

  @override
  Future<Result<List<CategoryModel>, AppError>> getByType(CategoryType type) async {
    return Success(categories.where((c) => c.type == type).toList());
  }
}

class FakeBudgetRepository implements BudgetRepository {
  final List<BudgetModel> budgets = [];

  @override
  Future<Result<BudgetModel, AppError>> create(BudgetModel budget) async {
    budgets.add(budget);
    return Success(budget);
  }

  @override
  Future<Result<void, AppError>> update(BudgetModel budget) async {
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) budgets[index] = budget;
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    budgets.removeWhere((b) => b.id == id);
    return const Success(null);
  }

  @override
  Future<Result<BudgetModel?, AppError>> getById(String id) async {
    try {
      return Success(budgets.firstWhere((b) => b.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getAll() async => Success(List.of(budgets));

  @override
  Future<Result<List<BudgetModel>, AppError>> getActive() async {
    return Success(budgets.where((b) => b.isActive).toList());
  }

  @override
  Future<Result<List<BudgetModel>, AppError>> getByPeriod(BudgetPeriod period) async {
    return Success(budgets.where((b) => b.period == period).toList());
  }
}

class FakeAccountRepository implements AccountRepository {
  final List<AccountModel> accounts = [];

  @override
  Future<Result<AccountModel, AppError>> create(AccountModel account) async {
    accounts.add(account);
    return Success(account);
  }

  @override
  Future<Result<void, AppError>> update(AccountModel account) async {
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) accounts[index] = account;
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    accounts.removeWhere((a) => a.id == id);
    return const Success(null);
  }

  @override
  Future<Result<AccountModel?, AppError>> getById(String id) async {
    try {
      return Success(accounts.firstWhere((a) => a.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<AccountModel>, AppError>> getAll() async => Success(List.of(accounts));

  @override
  Future<Result<List<AccountModel>, AppError>> getActive() async {
    return Success(accounts.where((a) => a.isActive).toList());
  }
}

class FailingTransactionRepository extends FakeTransactionRepository {
  final bool isCreateFailing;
  final bool isUpdateFailing;
  final bool isDeleteFailing;
  final bool isCategoryDateLookupFailing;
  final bool isDateRangeLookupFailing;
  final bool isGetAllFailing;
  final bool isGetRecentFailing;
  final bool isGetByAccountFailing;

  FailingTransactionRepository(
    super.seed, {
    this.isCreateFailing = false,
    this.isUpdateFailing = false,
    this.isDeleteFailing = false,
    this.isCategoryDateLookupFailing = false,
    this.isDateRangeLookupFailing = false,
    this.isGetAllFailing = false,
    this.isGetRecentFailing = false,
    this.isGetByAccountFailing = false,
  });

  @override
  Future<Result<TransactionModel, AppError>> create(TransactionModel transaction) async {
    if (isCreateFailing) return Failure(DatabaseError('create failed'));
    return super.create(transaction);
  }

  @override
  Future<Result<void, AppError>> update(TransactionModel transaction) async {
    if (isUpdateFailing) return Failure(DatabaseError('update failed'));
    return super.update(transaction);
  }

  @override
  Future<Result<void, AppError>> delete(String id) async {
    if (isDeleteFailing) return Failure(DatabaseError('delete failed'));
    return super.delete(id);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    if (isCategoryDateLookupFailing) return Failure(DatabaseError('lookup failed'));
    return super.getByCategoryAndDateRange(categoryId, start, end);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (isDateRangeLookupFailing) return Failure(DatabaseError('range lookup failed'));
    return super.getByDateRange(start, end);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getAll() async {
    if (isGetAllFailing) return Failure(DatabaseError('getAll failed'));
    return super.getAll();
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getRecent(int limit) async {
    if (isGetRecentFailing) return Failure(DatabaseError('getRecent failed'));
    return super.getRecent(limit);
  }

  @override
  Future<Result<List<TransactionModel>, AppError>> getByAccount(String accountId) async {
    if (isGetByAccountFailing) return Failure(DatabaseError('getByAccount failed'));
    return super.getByAccount(accountId);
  }
}

class FailingExchangeRateRepository extends FakeExchangeRateRepository {
  final bool isCreateFailing;
  final bool isLookupFailing;
  final bool isCleanupFailing;

  FailingExchangeRateRepository({
    List<ExchangeRateModel>? seed,
    this.isCreateFailing = false,
    this.isLookupFailing = false,
    this.isCleanupFailing = false,
  }) : super(seed);

  @override
  Future<Result<ExchangeRateModel, AppError>> create(ExchangeRateModel rate) async {
    if (isCreateFailing) return Failure(DatabaseError('create failed'));
    return super.create(rate);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    if (isLookupFailing) return Failure(DatabaseError('lookup failed'));
    return super.getRateForDate(fromCurrency, toCurrency, date);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getNearestRateOnOrBefore(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    if (isLookupFailing) return Failure(DatabaseError('lookup failed'));
    return super.getNearestRateOnOrBefore(fromCurrency, toCurrency, date);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (isLookupFailing) return Failure(DatabaseError('lookup failed'));
    return super.getLatestRate(fromCurrency, toCurrency);
  }

  @override
  Future<Result<void, AppError>> deleteOldRates(DateTime before) async {
    if (isCleanupFailing) return Failure(DatabaseError('cleanup failed'));
    return super.deleteOldRates(before);
  }

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  ) async {
    if (isLookupFailing) return Failure(DatabaseError('lookup failed'));
    return super.getRatesForDateRange(fromCurrency, toCurrency, start, end);
  }
}

class FailingFinancialActivityLogRepository extends FakeFinancialActivityLogRepository {
  final bool isCreateFailing;
  final bool isGetRecentFailing;

  FailingFinancialActivityLogRepository({
    this.isCreateFailing = true,
    this.isGetRecentFailing = false,
  });

  @override
  Future<Result<FinancialActivityLogModel, AppError>> create(
    FinancialActivityLogModel entry,
  ) async {
    if (isCreateFailing) return Failure(DatabaseError('activity log write failed'));
    return super.create(entry);
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, AppError>> getRecent(int limit) async {
    if (isGetRecentFailing) return Failure(DatabaseError('activity log lookup failed'));
    return super.getRecent(limit);
  }
}

class FailingCategoryRepository extends FakeCategoryRepository {
  final bool isGetAllFailing;

  FailingCategoryRepository({this.isGetAllFailing = false});

  @override
  Future<Result<List<CategoryModel>, AppError>> getAll() async {
    if (isGetAllFailing) return Failure(DatabaseError('getAll failed'));
    return super.getAll();
  }
}

class FailingBudgetRepository extends FakeBudgetRepository {
  final bool isGetActiveFailing;

  FailingBudgetRepository({this.isGetActiveFailing = false});

  @override
  Future<Result<List<BudgetModel>, AppError>> getActive() async {
    if (isGetActiveFailing) return Failure(DatabaseError('getActive failed'));
    return super.getActive();
  }
}

class FailingAccountRepository extends FakeAccountRepository {
  final bool isGetAllFailing;
  final bool isGetActiveFailing;

  FailingAccountRepository({
    this.isGetAllFailing = false,
    this.isGetActiveFailing = false,
  });

  @override
  Future<Result<List<AccountModel>, AppError>> getAll() async {
    if (isGetAllFailing) return Failure(DatabaseError('getAll failed'));
    return super.getAll();
  }

  @override
  Future<Result<List<AccountModel>, AppError>> getActive() async {
    if (isGetActiveFailing) return Failure(DatabaseError('getActive failed'));
    return super.getActive();
  }
}
