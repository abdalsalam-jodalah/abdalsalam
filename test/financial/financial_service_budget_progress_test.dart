import 'package:abdalsalam/data/models/financial/budget_model.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/features/financial/services/currency_conversion_service.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/features/financial/services/financial_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _StubCurrencyService extends CurrencyService {
  _StubCurrencyService() : super(LoggerService.forModule('test'), StorageGateway.instance);

  @override
  Future<double> getExchangeRate(Currency targetCurrency) async => 1.0;
}

TransactionModel _expense({
  required String id,
  required String categoryId,
  required double amount,
  required String currency,
  required DateTime date,
}) {
  return TransactionModel(
    id: id,
    userId: 'u1',
    type: TransactionType.expense,
    amount: amount,
    currency: currency,
    categoryId: categoryId,
    date: date,
    description: 'test expense',
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('FinancialService.getBudgetProgress', () {
    late FakeTransactionRepository transactionRepo;
    late FinancialService service;
    final budget = BudgetModel(
      id: 'budget-1',
      userId: 'u1',
      categoryId: 'groceries',
      amount: 100,
      period: BudgetPeriod.monthly,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31, 23, 59, 59),
      alertThreshold: 80,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      transactionRepo = FakeTransactionRepository();
      final exchangeRateRepo = FakeExchangeRateRepository([
        ExchangeRateModel(
          id: 'rate-1',
          fromCurrency: 'ILS',
          toCurrency: 'USD',
          rate: 0.25, // 1 ILS = 0.25 USD  =>  1 USD = 4 ILS
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ]);
      service = FinancialService(
        transactionRepo: transactionRepo,
        categoryRepo: FakeCategoryRepository(),
        budgetRepo: FakeBudgetRepository(),
        accountRepo: FakeAccountRepository(),
        activityLogRepo: FakeFinancialActivityLogRepository(),
        conversionService: CurrencyConversionService(exchangeRateRepo, _StubCurrencyService()),
      );
    });

    test('spend only counts transactions in the budget\'s category', () async {
      transactionRepo.transactions.addAll([
        _expense(
          id: '1',
          categoryId: 'groceries',
          amount: 30,
          currency: 'ILS',
          date: DateTime(2026, 1, 5),
        ),
        _expense(
          id: '2',
          categoryId: 'entertainment', // different category — must be excluded
          amount: 500,
          currency: 'ILS',
          date: DateTime(2026, 1, 6),
        ),
      ]);

      final result = await service.getBudgetProgress(budget);

      expect(result.isSuccess, isTrue);
      expect(result.data!['spent'], 30.0);
    });

    test('spend converts non-base-currency transactions before summing', () async {
      transactionRepo.transactions.addAll([
        _expense(
          id: '1',
          categoryId: 'groceries',
          amount: 20,
          currency: 'ILS',
          date: DateTime(2026, 1, 5),
        ),
        _expense(
          id: '2',
          categoryId: 'groceries',
          amount: 5, // 5 USD -> 20 ILS at the seeded 0.25 rate
          currency: 'USD',
          date: DateTime(2026, 1, 6),
        ),
      ]);

      final result = await service.getBudgetProgress(budget);

      expect(result.data!['spent'], closeTo(40.0, 0.001));
    });

    test('flags isOverBudget and isNearLimit correctly', () async {
      transactionRepo.transactions.add(_expense(
        id: '1',
        categoryId: 'groceries',
        amount: 90,
        currency: 'ILS',
        date: DateTime(2026, 1, 5),
      ));

      final result = await service.getBudgetProgress(budget);

      expect(result.data!['isOverBudget'], isFalse);
      expect(result.data!['isNearLimit'], isTrue); // 90% >= 80% threshold
    });

    test('income transactions in the same category are not counted as spend', () async {
      transactionRepo.transactions.add(TransactionModel(
        id: '1',
        userId: 'u1',
        type: TransactionType.income,
        amount: 1000,
        currency: 'ILS',
        categoryId: 'groceries',
        date: DateTime(2026, 1, 5),
        description: 'refund',
        createdAt: DateTime(2026, 1, 5),
        updatedAt: DateTime(2026, 1, 5),
      ));

      final result = await service.getBudgetProgress(budget);

      expect(result.data!['spent'], 0.0);
    });
  });
}
