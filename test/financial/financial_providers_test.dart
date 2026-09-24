import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/account_repository.dart';
import 'package:abdalsalam/data/repositories/financial/budget_repository.dart';
import 'package:abdalsalam/data/repositories/financial/category_repository.dart';
import 'package:abdalsalam/data/repositories/financial/exchange_rate_repository.dart';
import 'package:abdalsalam/data/repositories/financial/financial_activity_log_repository.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository.dart';
import 'package:abdalsalam/features/financial/providers/financial_providers.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';

import 'fakes.dart';

const _unreachableApiStatus = 503;
final _logger = LoggerService.forModule('FinancialProvidersTest');

/// The real [currencyServiceProvider] fires a background HTTP refresh as
/// soon as it's built; this stubs that HTTP client so tests never touch the
/// network and stay deterministic.
CurrencyService _offlineCurrencyService() {
  final client = MockClient((request) async => http.Response('unavailable', _unreachableApiStatus));
  return CurrencyService(_logger, StorageGateway.instance, httpClient: client);
}

ProviderContainer _buildContainer({
  TransactionRepository? transactionRepo,
  CategoryRepository? categoryRepo,
  BudgetRepository? budgetRepo,
  AccountRepository? accountRepo,
  FinancialActivityLogRepository? activityLogRepo,
  ExchangeRateRepository? exchangeRateRepo,
}) {
  return ProviderContainer(overrides: [
    transactionRepositoryProvider.overrideWithValue(transactionRepo ?? FakeTransactionRepository()),
    categoryRepositoryProvider.overrideWithValue(categoryRepo ?? FakeCategoryRepository()),
    budgetRepositoryProvider.overrideWithValue(budgetRepo ?? FakeBudgetRepository()),
    accountRepositoryProvider.overrideWithValue(accountRepo ?? FakeAccountRepository()),
    financialActivityLogRepositoryProvider
        .overrideWithValue(activityLogRepo ?? FakeFinancialActivityLogRepository()),
    exchangeRateRepositoryProvider.overrideWithValue(exchangeRateRepo ?? FakeExchangeRateRepository()),
    currencyServiceProvider.overrideWithValue(_offlineCurrencyService()),
  ]);
}

TransactionModel _transaction({
  required String id,
  required String categoryId,
  String? accountId,
  TransactionType type = TransactionType.expense,
  double amount = 100,
  String currency = 'ILS',
  required DateTime date,
}) {
  return TransactionModel(
    id: id,
    userId: 'abdalsalam',
    type: type,
    amount: amount,
    currency: currency,
    categoryId: categoryId,
    accountId: accountId,
    date: date,
    description: 'test transaction $id',
    createdAt: date,
    updatedAt: date,
  );
}

CategoryModel _category(String id) {
  final now = DateTime(2026, 1, 1);
  return CategoryModel(
    id: id,
    userId: 'abdalsalam',
    name: 'Category $id',
    type: CategoryType.expense,
    icon: Icons.category,
    color: Colors.blue,
    createdAt: now,
    updatedAt: now,
  );
}

BudgetModel _budget({
  required String id,
  required String categoryId,
  double amount = 500,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final now = DateTime(2026, 1, 1);
  return BudgetModel(
    id: id,
    userId: 'abdalsalam',
    categoryId: categoryId,
    amount: amount,
    period: BudgetPeriod.monthly,
    startDate: startDate,
    endDate: endDate,
    createdAt: now,
    updatedAt: now,
  );
}

AccountModel _account({
  required String id,
  double initialBalance = 1000,
  String currency = 'ILS',
  bool isActive = true,
}) {
  final now = DateTime(2026, 1, 1);
  return AccountModel(
    id: id,
    userId: 'abdalsalam',
    name: 'Account $id',
    type: AccountType.cash,
    currency: currency,
    initialBalance: initialBalance,
    iconKey: 'wallet',
    colorValue: 0xFF4CAF50,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

FinancialActivityLogModel _activityLogEntry(String id) {
  final now = DateTime(2026, 1, 1);
  return FinancialActivityLogModel(
    id: id,
    userId: 'abdalsalam',
    entityType: FinancialEntityType.transaction,
    action: FinancialActionType.created,
    entityId: 'txn-$id',
    summary: 'created transaction',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('allTransactionsProvider', () {
    test('should return the repository transactions on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(id: 't1', categoryId: 'c1', date: DateTime(2026, 1, 5)),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(allTransactionsProvider.future);

      expect(result, hasLength(1));
      expect(result.first.id, 't1');
    });

    test('should surface a repository failure as AsyncError, not an empty list', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isGetAllFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(allTransactionsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('recentTransactionsProvider', () {
    test('should return recent transactions on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(id: 't1', categoryId: 'c1', date: DateTime(2026, 1, 5)),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(recentTransactionsProvider.future);

      expect(result, hasLength(1));
    });

    test('should surface a repository failure as AsyncError', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isGetRecentFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(recentTransactionsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('allCategoriesProvider', () {
    test('should return categories on success', () async {
      final repo = FakeCategoryRepository()..categories.add(_category('c1'));
      final container = _buildContainer(categoryRepo: repo);
      addTearDown(container.dispose);

      final result = await container.read(allCategoriesProvider.future);

      expect(result, hasLength(1));
    });

    test('should surface a repository failure as AsyncError, not an empty list', () async {
      final container = _buildContainer(
        categoryRepo: FailingCategoryRepository(isGetAllFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(allCategoriesProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('activeBudgetsProvider', () {
    test('should return active budgets on success', () async {
      final repo = FakeBudgetRepository()
        ..budgets.add(_budget(
          id: 'b1',
          categoryId: 'c1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        ));
      final container = _buildContainer(budgetRepo: repo);
      addTearDown(container.dispose);

      final result = await container.read(activeBudgetsProvider.future);

      expect(result, hasLength(1));
    });

    test('should surface a repository failure as AsyncError, not an empty list', () async {
      final container = _buildContainer(
        budgetRepo: FailingBudgetRepository(isGetActiveFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeBudgetsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('allAccountsProvider / activeAccountsProvider', () {
    test('allAccountsProvider should return accounts on success', () async {
      final repo = FakeAccountRepository()..accounts.add(_account(id: 'a1'));
      final container = _buildContainer(accountRepo: repo);
      addTearDown(container.dispose);

      final result = await container.read(allAccountsProvider.future);

      expect(result, hasLength(1));
    });

    test('allAccountsProvider should surface a repository failure as AsyncError', () async {
      final container = _buildContainer(
        accountRepo: FailingAccountRepository(isGetAllFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(allAccountsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('activeAccountsProvider should return active accounts on success', () async {
      final repo = FakeAccountRepository()..accounts.add(_account(id: 'a1'));
      final container = _buildContainer(accountRepo: repo);
      addTearDown(container.dispose);

      final result = await container.read(activeAccountsProvider.future);

      expect(result, hasLength(1));
    });

    test('activeAccountsProvider should surface a repository failure as AsyncError, not an empty list',
        () async {
      final container = _buildContainer(
        accountRepo: FailingAccountRepository(isGetActiveFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(activeAccountsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('recentActivityLogProvider', () {
    test('should return recent entries on success', () async {
      final repo = FakeFinancialActivityLogRepository()..entries.add(_activityLogEntry('l1'));
      final container = _buildContainer(activityLogRepo: repo);
      addTearDown(container.dispose);

      final result = await container.read(recentActivityLogProvider.future);

      expect(result, hasLength(1));
    });

    test('should surface a repository failure as AsyncError, not an empty list', () async {
      final container = _buildContainer(
        activityLogRepo: FailingFinancialActivityLogRepository(
          isCreateFailing: false,
          isGetRecentFailing: true,
        ),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(recentActivityLogProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('financialSummaryProvider (autoDispose family)', () {
    final dateRange = DateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));

    test('should return income/expense/balance on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(
            id: 't1',
            categoryId: 'c1',
            type: TransactionType.income,
            amount: 300,
            date: DateTime(2026, 1, 5),
          ),
          _transaction(
            id: 't2',
            categoryId: 'c1',
            type: TransactionType.expense,
            amount: 120,
            date: DateTime(2026, 1, 6),
          ),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(financialSummaryProvider(dateRange).future);

      expect(result['income'], 300);
      expect(result['expense'], 120);
      expect(result['balance'], 180);
    });

    test('should surface a failure as AsyncError instead of a zeroed summary', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isDateRangeLookupFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(financialSummaryProvider(dateRange).future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('categoryTotalsProvider (autoDispose family)', () {
    final dateRange = DateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 31));

    test('should return totals per category on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(id: 't1', categoryId: 'c1', amount: 50, date: DateTime(2026, 1, 5)),
          _transaction(id: 't2', categoryId: 'c1', amount: 25, date: DateTime(2026, 1, 6)),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(categoryTotalsProvider(dateRange).future);

      expect(result['c1'], 75);
    });

    test('should surface a failure as AsyncError instead of an empty map', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isDateRangeLookupFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(categoryTotalsProvider(dateRange).future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('budgetProgressProvider (autoDispose family)', () {
    final budget = _budget(
      id: 'b1',
      categoryId: 'c1',
      amount: 200,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
    );

    test('should return spend/remaining/percentage on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(id: 't1', categoryId: 'c1', amount: 50, date: DateTime(2026, 1, 5)),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(budgetProgressProvider(budget).future);

      expect(result['spent'], 50);
      expect(result['remaining'], 150);
    });

    test('should surface a failure as AsyncError instead of an empty map', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isCategoryDateLookupFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(budgetProgressProvider(budget).future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('accountBalanceProvider (autoDispose family)', () {
    final account = _account(id: 'a1', initialBalance: 1000);

    test('should return the derived balance on success', () async {
      final container = _buildContainer(
        transactionRepo: FakeTransactionRepository([
          _transaction(
            id: 't1',
            categoryId: 'c1',
            accountId: 'a1',
            type: TransactionType.income,
            amount: 250,
            date: DateTime(2026, 1, 5),
          ),
        ]),
      );
      addTearDown(container.dispose);

      final result = await container.read(accountBalanceProvider(account).future);

      expect(result, 1250);
    });

    test('should surface a failure as AsyncError instead of falling back to the initial balance', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isGetByAccountFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(accountBalanceProvider(account).future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('netWorthProvider', () {
    test('should return a net worth summary on success', () async {
      final container = _buildContainer(
        accountRepo: FakeAccountRepository()..accounts.add(_account(id: 'a1', initialBalance: 500)),
      );
      addTearDown(container.dispose);

      final result = await container.read(netWorthProvider.future);

      expect(result['netWorth'], 500);
    });

    test('should surface a failure as AsyncError instead of an empty summary', () async {
      final container = _buildContainer(
        accountRepo: FailingAccountRepository(isGetActiveFailing: true),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(netWorthProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('financialStartupTasksProvider', () {
    test('should complete without throwing even when recurring catch-up fails, logging instead', () async {
      final container = _buildContainer(
        transactionRepo: FailingTransactionRepository([], isGetAllFailing: true),
      );
      addTearDown(container.dispose);

      await container.read(financialStartupTasksProvider.future);

      expect(container.read(financialStartupTasksProvider), const AsyncData<void>(null));
    });
  });
}
