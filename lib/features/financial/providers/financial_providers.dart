import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../data/repositories/financial/transaction_repository_impl.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/financial/budget_repository.dart';
import '../../../data/repositories/financial/account_repository.dart';
import '../../../data/repositories/financial/exchange_rate_repository.dart';
import '../../../data/repositories/financial/exchange_rate_repository_impl.dart';
import '../../../data/repositories/financial/financial_activity_log_repository.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/financial_service.dart';
import '../services/currency_service.dart';
import '../services/currency_conversion_service.dart';
import '../services/enhanced_currency_service.dart';
import '../services/financial_activity_logger.dart';
import '../services/recurring_transaction_generator.dart';
import '../services/financial_data_seeder.dart';
import 'category_repository_impl.dart';
import 'budget_repository_impl.dart';
import 'account_repository_impl.dart';
import 'financial_activity_log_repository_impl.dart';

// Currency Service Provider
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final logger = LoggerService.forModule(
    'CurrencyService',
    moduleType: logic.ModuleType.service,
  );
  final storage = ref.watch(storageGatewayProvider);
  final service = CurrencyService(logger, storage);
  service.initialize().then((result) {
    if (result.isFailure) {
      logger.warning('Currency service initialization failed: ${result.error}');
    }
  });
  return service;
});

// Data Seeder Provider
final financialDataSeederProvider = Provider<FinancialDataSeeder>((ref) {
  return FinancialDataSeeder(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    logger: LoggerService.forModule(
      'FinancialDataSeeder',
      moduleType: logic.ModuleType.service,
    ),
  );
});

// Repository Providers
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'TransactionRepository',
    moduleType: logic.ModuleType.repository,
  );
  return TransactionRepositoryImpl(storage, logger);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'CategoryRepository',
    moduleType: logic.ModuleType.repository,
  );
  return CategoryRepositoryImpl(storage, logger);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'BudgetRepository',
    moduleType: logic.ModuleType.repository,
  );
  return BudgetRepositoryImpl(storage, logger);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'AccountRepository',
    moduleType: logic.ModuleType.repository,
  );
  return AccountRepositoryImpl(storage, logger);
});

final financialActivityLogRepositoryProvider =
    Provider<FinancialActivityLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'FinancialActivityLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return FinancialActivityLogRepositoryImpl(storage, logger);
});

// Exchange Rate Repository Provider (moved here from dashboard_providers.dart —
// this is financial-domain infrastructure, dashboard reuses it, not the reverse)
final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  final logger = LoggerService.forModule(
    'ExchangeRateRepository',
    moduleType: logic.ModuleType.repository,
  );
  final storage = ref.watch(storageGatewayProvider);
  return ExchangeRateRepositoryImpl(storage, logger);
});

final enhancedCurrencyServiceProvider = Provider<EnhancedCurrencyService>((ref) {
  final logger = LoggerService.forModule(
    'EnhancedCurrencyService',
    moduleType: logic.ModuleType.service,
  );
  final repository = ref.watch(exchangeRateRepositoryProvider);
  final currencyService = ref.watch(currencyServiceProvider);
  return EnhancedCurrencyService(repository, logger, currencyService);
});

final currencyConversionServiceProvider = Provider<CurrencyConversionService>((ref) {
  return CurrencyConversionService(
    ref.watch(exchangeRateRepositoryProvider),
    ref.watch(currencyServiceProvider),
    LoggerService.forModule(
      'CurrencyConversionService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

// Service Provider
final financialServiceProvider = Provider<FinancialService>((ref) {
  return FinancialService(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    accountRepo: ref.watch(accountRepositoryProvider),
    activityLogRepo: ref.watch(financialActivityLogRepositoryProvider),
    conversionService: ref.watch(currencyConversionServiceProvider),
    logger: LoggerService.forModule(
      'FinancialService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final recurringTransactionGeneratorProvider =
    Provider<RecurringTransactionGenerator>((ref) {
  final logger = LoggerService.forModule(
    'RecurringTransactionGenerator',
    moduleType: logic.ModuleType.service,
  );
  return RecurringTransactionGenerator(
    ref.watch(transactionRepositoryProvider),
    FinancialActivityLogger(ref.watch(financialActivityLogRepositoryProvider), logger),
    logger,
  );
});

/// Runs once per app session (watched from the tabbed [FinancialScreen]'s
/// first build): catches up any due recurring transactions and refreshes
/// exchange rates, so historical conversions keep accumulating daily.
final financialStartupTasksProvider = FutureProvider<void>((ref) async {
  final logger = LoggerService.forModule(
    'FinancialStartupTasks',
    moduleType: logic.ModuleType.service,
  );
  final recurringResult =
      await ref.read(recurringTransactionGeneratorProvider).catchUpDueRecurrences();
  if (recurringResult.isFailure) {
    logger.error('Recurring transaction catch-up failed: ${recurringResult.error}');
  }
  final syncResult = await ref.read(enhancedCurrencyServiceProvider).syncDailyRates();
  if (syncResult.isFailure) {
    logger.warning('Daily exchange rate sync failed: ${syncResult.error}');
  }
});

// Data Providers
final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getAll();
  return result.getOrThrow();
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getRecent(10);
  return result.getOrThrow();
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getAll();
  return result.getOrThrow();
});

final activeBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final result = await repo.getActive();
  return result.getOrThrow();
});

final allAccountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  final result = await repo.getAll();
  return result.getOrThrow();
});

final activeAccountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  final result = await repo.getActive();
  return result.getOrThrow();
});

// Financial Summary Provider
final financialSummaryProvider =
    FutureProvider.autoDispose.family<Map<String, double>, DateRange>(
  (ref, dateRange) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getFinancialSummary(
      dateRange.start,
      dateRange.end,
    );
    return result.getOrThrow();
  },
);

// Category Totals Provider
final categoryTotalsProvider =
    FutureProvider.autoDispose.family<Map<String, double>, DateRange>(
  (ref, dateRange) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getCategoryTotals(
      dateRange.start,
      dateRange.end,
    );
    return result.getOrThrow();
  },
);

// Budget Progress Provider
final budgetProgressProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, BudgetModel>(
  (ref, budget) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getBudgetProgress(budget);
    return result.getOrThrow();
  },
);

// Account Balance Provider (derived: initial balance + that account's transactions)
final accountBalanceProvider = FutureProvider.autoDispose.family<double, AccountModel>(
  (ref, account) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getAccountBalance(account);
    return result.getOrThrow();
  },
);

// Net Worth / Overall Summary Provider
final netWorthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(financialServiceProvider);
  final result = await service.getNetWorthSummary();
  return result.getOrThrow();
});

// Recent Financial Activity Log Provider
final recentActivityLogProvider =
    FutureProvider<List<FinancialActivityLogModel>>((ref) async {
  final repo = ref.watch(financialActivityLogRepositoryProvider);
  final result = await repo.getRecent(50);
  return result.getOrThrow();
});

// Helper class for date ranges
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
