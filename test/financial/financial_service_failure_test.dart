import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/errors/financial_errors.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/financial/transaction_model.dart';
import 'package:abdalsalam/data/repositories/financial/financial_activity_log_repository.dart';
import 'package:abdalsalam/data/repositories/financial/transaction_repository.dart';
import 'package:abdalsalam/features/financial/services/currency_conversion_service.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/features/financial/services/exchange_rate_quote.dart';
import 'package:abdalsalam/features/financial/services/financial_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _logger = LoggerService.forModule('FinancialServiceFailureTest');

class _StubCurrencyService extends CurrencyService {
  _StubCurrencyService() : super(LoggerService.forModule('test'), StorageGateway.instance);

  @override
  Future<Result<ExchangeRateQuote, AppError>> getExchangeRate(Currency targetCurrency) async =>
      const Success(ExchangeRateQuote(rate: 0.25, fetchedAt: null, isFallback: false));
}

TransactionModel _transaction({required String id, required String currency, double amount = 10}) {
  final date = DateTime(2026, 1, 5);
  return TransactionModel(
    id: id,
    userId: 'u1',
    type: TransactionType.expense,
    amount: amount,
    currency: currency,
    categoryId: 'groceries',
    date: date,
    description: 'test expense',
    createdAt: date,
    updatedAt: date,
  );
}

FinancialService _createService(
  TransactionRepository transactionRepo, {
  FinancialActivityLogRepository? activityLogRepo,
}) {
  return FinancialService(
    transactionRepo: transactionRepo,
    categoryRepo: FakeCategoryRepository(),
    budgetRepo: FakeBudgetRepository(),
    accountRepo: FakeAccountRepository(),
    activityLogRepo: activityLogRepo ?? FakeFinancialActivityLogRepository(),
    conversionService: CurrencyConversionService(
      FakeExchangeRateRepository(),
      _StubCurrencyService(),
      _logger,
    ),
    logger: _logger,
  );
}

void main() {
  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 1, 31);

  group('FinancialService.getFinancialSummary', () {
    test('should sum converted income and expense', () async {
      final service = _createService(FakeTransactionRepository([
        _transaction(id: '1', currency: 'ILS', amount: 20),
        _transaction(id: '2', currency: 'USD', amount: 5),
      ]));

      final result = await service.getFinancialSummary(start, end);

      expect(result.data!['expense'], closeTo(40, 0.001));
    });

    test('should return failure when the repository fails', () async {
      final service = _createService(FailingTransactionRepository([], isDateRangeLookupFailing: true));

      final result = await service.getFinancialSummary(start, end);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });

    test('should return a typed failure instead of throwing for an unknown currency', () async {
      final service = _createService(FakeTransactionRepository([
        _transaction(id: '1', currency: 'XYZ'),
      ]));

      final result = await service.getFinancialSummary(start, end);

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
    });
  });

  group('FinancialService.getCategoryTotals', () {
    test('should return failure when a conversion fails', () async {
      final service = _createService(FakeTransactionRepository([
        _transaction(id: '1', currency: 'XYZ'),
      ]));

      final result = await service.getCategoryTotals(start, end);

      expect(result.isFailure, isTrue);
    });
  });

  group('FinancialService.createTransaction', () {
    test('should return the repository failure and not report success', () async {
      final service = _createService(FailingTransactionRepository([], isCreateFailing: true));

      final result = await service.createTransaction(_transaction(id: '1', currency: 'ILS'));

      expect(result.isFailure, isTrue);
    });

    test('should still succeed when only the audit log write fails', () async {
      final transactionRepo = FakeTransactionRepository();
      final service = _createService(
        transactionRepo,
        activityLogRepo: FailingFinancialActivityLogRepository(),
      );

      final result = await service.createTransaction(_transaction(id: '1', currency: 'USD'));

      expect(result.isSuccess, isTrue);
      expect(transactionRepo.transactions, hasLength(1));
    });

    test('should still succeed when the audit conversion fails for an unknown currency', () async {
      final activityLogRepo = FakeFinancialActivityLogRepository();
      final service = _createService(FakeTransactionRepository(), activityLogRepo: activityLogRepo);

      final result = await service.createTransaction(_transaction(id: '1', currency: 'XYZ'));

      expect(result.isSuccess, isTrue);
      expect(activityLogRepo.entries.single.conversionRateUsed, isNull);
    });
  });
}
