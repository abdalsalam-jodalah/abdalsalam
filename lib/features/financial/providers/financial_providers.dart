import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/category.dart';
import '../../../data/models/financial/transaction.dart';
import '../../../data/repositories/financial/financial_category_repository.dart';
import '../../../data/repositories/financial/financial_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/financial_service.dart';

const financialDemoUserId = 'local-user';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = ref.watch(loggerProvider);
  return FinancialRepositoryImpl(storage, logger);
});

final financialCategoryRepositoryProvider = Provider<FinancialCategoryRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = ref.watch(loggerProvider);
  return FinancialCategoryRepository(storage, logger);
});

final financialServiceProvider = Provider<FinancialService>((ref) {
  final repo = ref.watch(financialRepositoryProvider);
  final categoryRepo = ref.watch(financialCategoryRepositoryProvider);
  final logger = ref.watch(loggerProvider);
  final reminders = ref.watch(reminderServiceProvider);
  return FinancialService(repo, logger, reminders: reminders, categoryRepository: categoryRepo);
});

final financialTransactionsControllerProvider =
    AsyncNotifierProvider<FinancialTransactionsController, List<Transaction>>(
  FinancialTransactionsController.new,
);

final financialCategoriesControllerProvider =
    AsyncNotifierProvider<FinancialCategoriesController, List<Category>>(
  FinancialCategoriesController.new,
);

class FinancialTransactionsController extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final service = ref.read(financialServiceProvider);
    await _ensureDefaultCategories();
    final result = await service.getTransactionsForUser(financialDemoUserId);
    return result.data ?? <Transaction>[];
  }

  Future<void> refreshData() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
    ref.invalidate(financialCategoriesControllerProvider);
  }

  Future<String?> addTransaction({
    required double amount,
    required String category,
    required String currency,
    required TransactionType direction,
    required DateTime date,
    required String description,
    String paymentMethod = 'Cash',
    List<String> tags = const <String>[],
  }) async {
    final service = ref.read(financialServiceProvider);
    final result = await service.createTransaction(
      userId: financialDemoUserId,
      amount: amount,
      category: category,
      currency: currency,
      direction: direction,
      date: date,
      description: description,
      paymentMethod: paymentMethod,
      tags: tags,
    );

    if (result.isFailure) {
      return result.error.toString();
    }

    await refreshData();
    return null;
  }

  Future<void> _ensureDefaultCategories() async {
    final service = ref.read(financialServiceProvider);
    final categories = await service.getCategories(financialDemoUserId);
    if (categories.isFailure) {
      return;
    }
    if (categories.data!.isNotEmpty) {
      return;
    }

    final seed = service.defaultCategories(userId: financialDemoUserId, now: DateTime.now());
    for (final item in seed) {
      await service.createCategory(item);
    }
  }
}

class FinancialCategoriesController extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final service = ref.read(financialServiceProvider);
    final result = await service.getCategories(financialDemoUserId);
    return result.data ?? <Category>[];
  }

  Future<String?> addCategory({
    required String name,
    required CategoryType type,
  }) async {
    final service = ref.read(financialServiceProvider);
    final result = await service.addCategory(
      userId: financialDemoUserId,
      name: name,
      type: type,
    );

    if (result.isFailure) {
      return result.error.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    ref.invalidate(financialTransactionsControllerProvider);
    return null;
  }
}

final financialDashboardSummaryProvider = FutureProvider.family<FinancialDashboardSummary, DateTimeRange>((ref, range) async {
  final service = ref.watch(financialServiceProvider);
  final summary = await service.getDashboardSummary(
    userId: financialDemoUserId,
    start: range.start,
    end: range.end,
  );
  if (summary.isFailure) {
    throw summary.error ?? Exception('Failed to load dashboard summary');
  }
  return summary.data!;
});

Result<void, AppError> ensureTransactionValid(Transaction? value) {
  if (value == null) {
    return Failure(ValidationError('Transaction is required'));
  }
  return const Success(null);
}
