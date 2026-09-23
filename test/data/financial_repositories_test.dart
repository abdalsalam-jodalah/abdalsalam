import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/data/models/financial/financial_activity_log_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/exchange_rate_repository_impl.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository_impl.dart';
import 'package:abdalsalam/features/financial/providers/account_repository_impl.dart';
import 'package:abdalsalam/features/financial/providers/budget_repository_impl.dart';
import 'package:abdalsalam/features/financial/providers/category_repository_impl.dart';
import 'package:abdalsalam/features/financial/providers/financial_activity_log_repository_impl.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String brokenId = 'broken';
const List<String> financialTables = [
  'transactions',
  'exchange_rates',
  'accounts',
  'budgets',
  'categories',
  'financial_activity_log',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  final timestamp = DateTime(2026, 1, 15);
  late LoggerService logger;

  Future<void> insertRowMissingMoneyFields(String table) async {
    await storage.upsertRecord(
      table: table,
      id: brokenId,
      record: {
        'id': brokenId,
        'createdAt': timestamp.toIso8601String(),
        'updatedAt': timestamp.toIso8601String(),
      },
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_financial_repositories_test.db');
    logger = LoggerService.forModule('FinancialRepositoriesTest');
    for (final table in financialTables) {
      await storage.clearTable(table);
    }
    storage.integrityReporter.clearReports();
  });

  group('TransactionRepositoryImpl', () {
    late TransactionRepositoryImpl repository;
    final transaction = TransactionModel(
      id: 'tx-good',
      userId: 'user-1',
      type: TransactionType.expense,
      amount: 30,
      currency: 'ILS',
      categoryId: 'cat-1',
      date: timestamp,
      description: 'Lunch',
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    setUp(() => repository = TransactionRepositoryImpl(storage, logger));

    test('should skip a corrupt row and report it when reading all transactions', () async {
      await repository.create(transaction);
      await insertRowMissingMoneyFields('transactions');

      final result = await repository.getAll();

      expect(result.data?.map((t) => t.id), ['tx-good']);
      expect(storage.integrityReporter.reports.single.recordId, brokenId);
    });

    test('should still total valid transactions when a corrupt row exists', () async {
      await repository.create(transaction);
      await insertRowMissingMoneyFields('transactions');

      final result = await repository.getTotalByType(
        TransactionType.expense,
        timestamp.subtract(const Duration(days: 1)),
        timestamp.add(const Duration(days: 1)),
      );

      expect(result.data, 30);
    });

    test('should return CorruptDataError from getById for a corrupt row', () async {
      await insertRowMissingMoneyFields('transactions');

      final result = await repository.getById(brokenId);

      expect(result.error, isA<CorruptDataError>());
    });

    test('should return null from getById when the row does not exist', () async {
      final result = await repository.getById('missing');

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });

  group('ExchangeRateRepositoryImpl', () {
    test('should skip a corrupt row when looking up the latest rate', () async {
      final repository = ExchangeRateRepositoryImpl(storage, logger);
      await repository.create(ExchangeRateModel(
        id: 'rate-good',
        fromCurrency: 'ILS',
        toCurrency: 'USD',
        rate: 0.27,
        date: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ));
      await insertRowMissingMoneyFields('exchange_rates');

      final result = await repository.getLatestRate('ILS', 'USD');

      expect(result.data?.id, 'rate-good');
      expect(storage.integrityReporter.reports.single.recordId, brokenId);
    });
  });

  group('AccountRepositoryImpl', () {
    test('should skip a corrupt row when reading active accounts', () async {
      final repository = AccountRepositoryImpl(storage, logger);
      await repository.create(AccountModel(
        id: 'acc-good',
        userId: 'user-1',
        name: 'Wallet',
        type: AccountType.cash,
        currency: 'ILS',
        initialBalance: 100,
        iconKey: 'account_balance_wallet',
        colorValue: 0xFF4CAF50,
        createdAt: timestamp,
        updatedAt: timestamp,
      ));
      await insertRowMissingMoneyFields('accounts');

      final result = await repository.getActive();

      expect(result.data?.map((a) => a.id), ['acc-good']);
    });
  });

  group('BudgetRepositoryImpl', () {
    test('should skip a corrupt row when reading budgets by period', () async {
      final repository = BudgetRepositoryImpl(storage, logger);
      await repository.create(BudgetModel(
        id: 'budget-good',
        userId: 'user-1',
        categoryId: 'cat-1',
        amount: 500,
        period: BudgetPeriod.custom,
        startDate: timestamp,
        endDate: timestamp.add(const Duration(days: 30)),
        createdAt: timestamp,
        updatedAt: timestamp,
      ));
      await insertRowMissingMoneyFields('budgets');

      final result = await repository.getByPeriod(BudgetPeriod.custom);

      expect(result.data?.map((b) => b.id), ['budget-good']);
    });
  });

  group('CategoryRepositoryImpl', () {
    test('should skip a corrupt row when reading categories by type', () async {
      final repository = CategoryRepositoryImpl(storage, logger);
      await repository.create(CategoryModel(
        id: 'cat-good',
        userId: 'user-1',
        name: 'Food',
        type: CategoryType.expense,
        icon: Icons.restaurant,
        color: const Color(0xFF4CAF50),
        createdAt: timestamp,
        updatedAt: timestamp,
      ));
      await insertRowMissingMoneyFields('categories');

      final result = await repository.getByType(CategoryType.expense);

      expect(result.data?.map((c) => c.id), ['cat-good']);
    });
  });

  group('FinancialActivityLogRepositoryImpl', () {
    test('should skip a corrupt row when reading recent entries', () async {
      final repository = FinancialActivityLogRepositoryImpl(storage, logger);
      await repository.create(FinancialActivityLogModel(
        id: 'log-good',
        userId: 'user-1',
        entityType: FinancialEntityType.transaction,
        action: FinancialActionType.created,
        entityId: 'tx-good',
        summary: 'Created',
        createdAt: timestamp,
        updatedAt: timestamp,
      ));
      await insertRowMissingMoneyFields('financial_activity_log');

      final result = await repository.getRecent(10);

      expect(result.data?.map((e) => e.id), ['log-good']);
    });
  });
}
