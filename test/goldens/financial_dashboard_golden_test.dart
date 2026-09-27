import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/financial/account_model.dart';
import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/category_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository.dart';
import 'package:abdalsalam/features/financial/providers/financial_providers.dart';
import 'package:abdalsalam/features/financial/screens/financial_dashboard_screen.dart';
import 'package:abdalsalam/features/financial/screens/transaction_form_screen.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../financial/fakes.dart';
import 'support/golden_harness.dart';

const _unreachableApiStatus = 503;
final _logger = LoggerService.forModule('FinancialGoldenTest');

CurrencyService _offlineCurrencyService() {
  final client = MockClient((request) async => http.Response('unavailable', _unreachableApiStatus));
  return CurrencyService(_logger, StorageGateway.instance, httpClient: client);
}

List<Override> _overrides({List<TransactionModel>? transactions}) {
  final now = DateTime.now();
  final groceries = CategoryModel(
    id: 'c-groceries',
    userId: 'abdalsalam',
    name: 'Groceries',
    type: CategoryType.expense,
    icon: Icons.local_grocery_store_rounded,
    color: const Color(0xFFF97316),
    createdAt: now,
    updatedAt: now,
  );
  final salary = CategoryModel(
    id: 'c-salary',
    userId: 'abdalsalam',
    name: 'Salary',
    type: CategoryType.income,
    icon: Icons.attach_money_rounded,
    color: const Color(0xFF10B981),
    createdAt: now,
    updatedAt: now,
  );
  final account = AccountModel(
    id: 'a-cash',
    userId: 'abdalsalam',
    name: 'Cash',
    type: AccountType.cash,
    currency: 'ILS',
    initialBalance: 1000,
    iconKey: 'cash',
    colorValue: 0xFF10B981,
    createdAt: now,
    updatedAt: now,
  );
  final budget = BudgetModel(
    id: 'b-groceries',
    userId: 'abdalsalam',
    categoryId: 'c-groceries',
    amount: 500,
    period: BudgetPeriod.monthly,
    startDate: DateTime(now.year, now.month, 1),
    endDate: DateTime(now.year, now.month + 1, 0),
    createdAt: now,
    updatedAt: now,
  );
  final seededTransactions = transactions ??
      [
        TransactionModel(
          id: 't-groceries',
          userId: 'abdalsalam',
          type: TransactionType.expense,
          amount: 120,
          currency: 'ILS',
          categoryId: 'c-groceries',
          date: now,
          description: 'Weekly groceries',
          createdAt: now,
          updatedAt: now,
        ),
        TransactionModel(
          id: 't-salary',
          userId: 'abdalsalam',
          type: TransactionType.income,
          amount: 3000,
          currency: 'ILS',
          categoryId: 'c-salary',
          date: now,
          description: 'Monthly salary',
          createdAt: now,
          updatedAt: now,
        ),
      ];

  return [
    transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository(seededTransactions)),
    categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()..categories.addAll([groceries, salary])),
    budgetRepositoryProvider.overrideWithValue(FakeBudgetRepository()..budgets.add(budget)),
    accountRepositoryProvider.overrideWithValue(FakeAccountRepository()..accounts.add(account)),
    financialActivityLogRepositoryProvider.overrideWithValue(FakeFinancialActivityLogRepository()),
    exchangeRateRepositoryProvider.overrideWithValue(FakeExchangeRateRepository()),
    currencyServiceProvider.overrideWithValue(_offlineCurrencyService()),
  ];
}

TransactionRepository _emptyTransactionRepo() => FakeTransactionRepository();

class _EmptySettingsService extends SettingsService {
  _EmptySettingsService() : super(StorageGateway.instance);

  @override
  Future<Map<String, dynamic>> getSettings() async => <String, dynamic>{};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadGoldenFonts);

  setUp(() async {
    await LoggerService.initialize();
  });

  for (final brightness in Brightness.values) {
    testWidgets('financial dashboard ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 2200));
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(),
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const FinancialDashboardScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/financial_dashboard_${brightness.name}.png'),
      );
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('transaction form ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1500));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(_emptyTransactionRepo()),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository()
              ..categories.addAll([
                CategoryModel(
                  id: 'c-groceries',
                  userId: 'abdalsalam',
                  name: 'Groceries',
                  type: CategoryType.expense,
                  icon: Icons.local_grocery_store_rounded,
                  color: const Color(0xFFF97316),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ]),
          ),
          budgetRepositoryProvider.overrideWithValue(FakeBudgetRepository()),
          accountRepositoryProvider.overrideWithValue(FakeAccountRepository()),
          financialActivityLogRepositoryProvider.overrideWithValue(FakeFinancialActivityLogRepository()),
          exchangeRateRepositoryProvider.overrideWithValue(FakeExchangeRateRepository()),
          currencyServiceProvider.overrideWithValue(_offlineCurrencyService()),
          settingsServiceProvider.overrideWithValue(_EmptySettingsService()),
        ],
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const TransactionFormScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('images/transaction_form_${brightness.name}.png'),
      );
    });
  }
}
