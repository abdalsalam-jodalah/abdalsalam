import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/repositories/financial/transaction_repository.dart';
import '../../../data/repositories/financial/transaction_repository_impl.dart';
import '../../../data/repositories/financial/category_repository.dart';
import '../../../data/repositories/financial/budget_repository.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../../../data/models/financial/category_model.dart';
import '../../../data/models/financial/budget_model.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/financial_service.dart';
import '../services/currency_service.dart';
import '../services/financial_data_seeder.dart';
import 'category_repository_impl.dart';
import 'budget_repository_impl.dart';

// Currency Service Provider
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final logger = LoggerService.forModule(
    'CurrencyService',
    moduleType: logic.ModuleType.service,
  );
  final storage = ref.watch(storageGatewayProvider);
  final service = CurrencyService(logger, storage);
  service.initialize();
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

// Service Provider
final financialServiceProvider = Provider<FinancialService>((ref) {
  return FinancialService(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
  );
});

// Data Providers
final allTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getAll();
  return result.data ?? [];
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final result = await repo.getRecent(10);
  return result.data ?? [];
});

final allCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getAll();
  return result.data ?? [];
});

final activeBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final result = await repo.getActive();
  return result.data ?? [];
});

// Financial Summary Provider
final financialSummaryProvider = FutureProvider.family<Map<String, double>, DateRange>(
  (ref, dateRange) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getFinancialSummary(
      dateRange.start,
      dateRange.end,
    );
    return result.data ?? {'income': 0, 'expense': 0, 'balance': 0};
  },
);

// Category Totals Provider
final categoryTotalsProvider = FutureProvider.family<Map<String, double>, DateRange>(
  (ref, dateRange) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getCategoryTotals(
      dateRange.start,
      dateRange.end,
    );
    return result.data ?? {};
  },
);

// Budget Progress Provider
final budgetProgressProvider = FutureProvider.family<Map<String, dynamic>, BudgetModel>(
  (ref, budget) async {
    final service = ref.watch(financialServiceProvider);
    final result = await service.getBudgetProgress(budget);
    return result.data ?? {};
  },
);

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
