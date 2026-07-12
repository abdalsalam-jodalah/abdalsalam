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
  Future<Result<TransactionModel, Error>> create(TransactionModel transaction) async {
    transactions.add(transaction);
    return Success(transaction);
  }

  @override
  Future<Result<void, Error>> update(TransactionModel transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) transactions[index] = transaction;
    return const Success(null);
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    transactions.removeWhere((t) => t.id == id);
    return const Success(null);
  }

  @override
  Future<Result<TransactionModel?, Error>> getById(String id) async {
    try {
      return Success(transactions.firstWhere((t) => t.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getAll() async => Success(List.of(transactions));

  @override
  Future<Result<List<TransactionModel>, Error>> getByDateRange(
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
  Future<Result<List<TransactionModel>, Error>> getByCategory(String categoryId) async {
    return Success(transactions.where((t) => t.categoryId == categoryId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByCategoryAndDateRange(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    final dateRangeResult = await getByDateRange(start, end);
    return Success(dateRangeResult.data!.where((t) => t.categoryId == categoryId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByAccount(String accountId) async {
    return Success(transactions.where((t) => t.accountId == accountId).toList());
  }

  @override
  Future<Result<List<TransactionModel>, Error>> getByType(TransactionType type) async {
    return Success(transactions.where((t) => t.type == type).toList());
  }

  @override
  Future<Result<double, Error>> getTotalByType(
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
  Future<Result<Map<String, double>, Error>> getTotalByCategory(
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
  Future<Result<List<TransactionModel>, Error>> getRecent(int limit) async {
    final sorted = List.of(transactions)..sort((a, b) => b.date.compareTo(a.date));
    return Success(sorted.take(limit).toList());
  }
}

class FakeExchangeRateRepository implements ExchangeRateRepository {
  final List<ExchangeRateModel> rates;

  FakeExchangeRateRepository([List<ExchangeRateModel>? seed]) : rates = seed ?? [];

  @override
  Future<Result<ExchangeRateModel, Error>> create(ExchangeRateModel rate) async {
    rates.add(rate);
    return Success(rate);
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getById(String id) async {
    try {
      return Success(rates.firstWhere((r) => r.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<ExchangeRateModel>, Error>> getAll() async => Success(List.of(rates));

  @override
  Future<Result<ExchangeRateModel?, Error>> getLatestRate(
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
  Future<Result<ExchangeRateModel?, Error>> getRateForDate(
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
  Future<Result<ExchangeRateModel?, Error>> getNearestRateOnOrBefore(
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
  Future<Result<List<ExchangeRateModel>, Error>> getRatesForDateRange(
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
  Future<Result<void, Error>> deleteOldRates(DateTime before) async {
    rates.removeWhere((r) => r.date.isBefore(before));
    return const Success(null);
  }
}

class FakeFinancialActivityLogRepository implements FinancialActivityLogRepository {
  final List<FinancialActivityLogModel> entries = [];

  @override
  Future<Result<FinancialActivityLogModel, Error>> create(
    FinancialActivityLogModel entry,
  ) async {
    entries.add(entry);
    return Success(entry);
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getAll() async =>
      Success(List.of(entries));

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getByEntityType(
    FinancialEntityType entityType,
  ) async {
    return Success(entries.where((e) => e.entityType == entityType).toList());
  }

  @override
  Future<Result<List<FinancialActivityLogModel>, Error>> getRecent(int limit) async {
    return Success(entries.take(limit).toList());
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryModel> categories = [];

  @override
  Future<Result<CategoryModel, Error>> create(CategoryModel category) async {
    categories.add(category);
    return Success(category);
  }

  @override
  Future<Result<void, Error>> update(CategoryModel category) async {
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index != -1) categories[index] = category;
    return const Success(null);
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    categories.removeWhere((c) => c.id == id);
    return const Success(null);
  }

  @override
  Future<Result<CategoryModel?, Error>> getById(String id) async {
    try {
      return Success(categories.firstWhere((c) => c.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<CategoryModel>, Error>> getAll() async => Success(List.of(categories));

  @override
  Future<Result<List<CategoryModel>, Error>> getByType(CategoryType type) async {
    return Success(categories.where((c) => c.type == type).toList());
  }
}

class FakeBudgetRepository implements BudgetRepository {
  final List<BudgetModel> budgets = [];

  @override
  Future<Result<BudgetModel, Error>> create(BudgetModel budget) async {
    budgets.add(budget);
    return Success(budget);
  }

  @override
  Future<Result<void, Error>> update(BudgetModel budget) async {
    final index = budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) budgets[index] = budget;
    return const Success(null);
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    budgets.removeWhere((b) => b.id == id);
    return const Success(null);
  }

  @override
  Future<Result<BudgetModel?, Error>> getById(String id) async {
    try {
      return Success(budgets.firstWhere((b) => b.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<BudgetModel>, Error>> getAll() async => Success(List.of(budgets));

  @override
  Future<Result<List<BudgetModel>, Error>> getActive() async {
    return Success(budgets.where((b) => b.isActive).toList());
  }

  @override
  Future<Result<List<BudgetModel>, Error>> getByPeriod(BudgetPeriod period) async {
    return Success(budgets.where((b) => b.period == period).toList());
  }
}

class FakeAccountRepository implements AccountRepository {
  final List<AccountModel> accounts = [];

  @override
  Future<Result<AccountModel, Error>> create(AccountModel account) async {
    accounts.add(account);
    return Success(account);
  }

  @override
  Future<Result<void, Error>> update(AccountModel account) async {
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) accounts[index] = account;
    return const Success(null);
  }

  @override
  Future<Result<void, Error>> delete(String id) async {
    accounts.removeWhere((a) => a.id == id);
    return const Success(null);
  }

  @override
  Future<Result<AccountModel?, Error>> getById(String id) async {
    try {
      return Success(accounts.firstWhere((a) => a.id == id));
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<List<AccountModel>, Error>> getAll() async => Success(List.of(accounts));

  @override
  Future<Result<List<AccountModel>, Error>> getActive() async {
    return Success(accounts.where((a) => a.isActive).toList());
  }
}
