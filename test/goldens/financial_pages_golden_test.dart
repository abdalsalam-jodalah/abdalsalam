import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/features/financial/providers/financial_providers.dart';
import 'package:abdalsalam/features/financial/screens/budgets_page.dart';
import 'package:abdalsalam/features/financial/screens/categories_page.dart';
import 'package:abdalsalam/features/financial/screens/transactions_page.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../financial/fakes.dart';
import 'support/golden_harness.dart';

const _unreachableApiStatus = 503;
final _logger = LoggerService.forModule('FinancialPagesGoldenTest');

CurrencyService _offlineCurrencyService() {
  final client = MockClient((request) async => http.Response('unavailable', _unreachableApiStatus));
  return CurrencyService(_logger, StorageGateway.instance, httpClient: client);
}

CategoryModel _category({
  required String id,
  required String name,
  required CategoryType type,
  required IconData icon,
  required Color color,
}) {
  final createdAt = DateTime(2026, 1, 1);
  return CategoryModel(
    id: id,
    userId: 'abdalsalam',
    name: name,
    type: type,
    icon: icon,
    color: color,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

TransactionModel _transaction({
  required String id,
  required TransactionType type,
  required double amount,
  required String categoryId,
  required DateTime date,
  required String description,
  String? paymentMethod,
}) {
  return TransactionModel(
    id: id,
    userId: 'abdalsalam',
    type: type,
    amount: amount,
    currency: 'ILS',
    categoryId: categoryId,
    date: date,
    description: description,
    paymentMethod: paymentMethod,
    createdAt: date,
    updatedAt: date,
  );
}

List<Override> _overrides({
  required List<CategoryModel> categories,
  required List<TransactionModel> transactions,
  required List<BudgetModel> budgets,
}) {
  return [
    transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository(transactions)),
    categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()..categories.addAll(categories)),
    budgetRepositoryProvider.overrideWithValue(FakeBudgetRepository()..budgets.addAll(budgets)),
    accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
    financialActivityLogRepositoryProvider.overrideWithValue(FakeFinancialActivityLogRepository()),
    exchangeRateRepositoryProvider.overrideWithValue(FakeExchangeRateRepository()),
    currencyServiceProvider.overrideWithValue(_offlineCurrencyService()),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadGoldenFonts);

  setUp(() async {
    await LoggerService.initialize();
  });

  final groceries = _category(
    id: 'c-groceries',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: Icons.shopping_cart,
    color: Colors.orange,
  );
  final salary = _category(
    id: 'c-salary',
    name: 'Salary',
    type: CategoryType.income,
    icon: Icons.work,
    color: Colors.green,
  );

  final transactions = [
    _transaction(
      id: 't-groceries',
      type: TransactionType.expense,
      amount: 145.5,
      categoryId: groceries.id,
      date: DateTime(2026, 9, 24, 9, 30),
      description: 'Weekly groceries',
      paymentMethod: 'Card',
    ),
    _transaction(
      id: 't-salary',
      type: TransactionType.income,
      amount: 9500,
      categoryId: salary.id,
      date: DateTime(2026, 9, 22, 14),
      description: 'Monthly salary',
      paymentMethod: 'Bank transfer',
    ),
    _transaction(
      id: 't-budget-spend',
      type: TransactionType.expense,
      amount: 300,
      categoryId: groceries.id,
      date: DateTime(2026, 1, 15),
      description: 'Supermarket run',
    ),
  ];

  final budget = BudgetModel(
    id: 'b-groceries',
    userId: 'abdalsalam',
    categoryId: groceries.id,
    amount: 500,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 2, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  for (final brightness in Brightness.values) {
    testWidgets('transactions ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1000));
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(categories: [groceries, salary], transactions: transactions, budgets: [budget]),
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const TransactionsPage(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/financial_transactions_${brightness.name}.png'));
    });

    testWidgets('budgets ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1000));
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(categories: [groceries, salary], transactions: transactions, budgets: [budget]),
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const BudgetsPage(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/financial_budgets_${brightness.name}.png'));
    });

    testWidgets('categories ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1000));
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(categories: [groceries, salary], transactions: transactions, budgets: [budget]),
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const CategoriesPage(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/financial_categories_${brightness.name}.png'));
    });
  }
}
