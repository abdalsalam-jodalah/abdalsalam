import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/errors/financial_errors.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/features/financial/services/currency_conversion_service.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/features/financial/services/exchange_rate_quote.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

final _logger = LoggerService.forModule('CurrencyConversionServiceTest');

class _StubCurrencyService extends CurrencyService {
  final double stubbedRate;
  int requestCount = 0;

  _StubCurrencyService(this.stubbedRate)
      : super(LoggerService.forModule('test'), StorageGateway.instance);

  @override
  Future<Result<ExchangeRateQuote, AppError>> getExchangeRate(Currency targetCurrency) async {
    requestCount++;
    return Success(ExchangeRateQuote(
      rate: stubbedRate,
      fetchedAt: DateTime(2026, 6, 1),
      isFallback: false,
    ));
  }
}

ExchangeRateModel _usdRate({required String id, required double rate, required DateTime date}) {
  return ExchangeRateModel(
    id: id,
    fromCurrency: 'ILS',
    toCurrency: 'USD',
    rate: rate,
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('CurrencyConversionService.convertToBase', () {
    test('same currency as base returns amount unchanged with rate 1.0', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository(),
        _StubCurrencyService(3.7),
        _logger,
      );

      final result = await service.convertToBase(
        amount: 100,
        fromCurrency: 'ILS',
        asOfDate: DateTime(2026, 1, 1),
      );

      expect(result.data!.convertedAmount, 100);
      expect(result.data!.rateUsed, 1.0);
      expect(result.data!.wasFallback, isFalse);
    });

    test('uses the exact-date stored rate when available', () async {
      final repo = FakeExchangeRateRepository([
        _usdRate(id: '1', rate: 0.27, date: DateTime(2026, 6, 1)),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(999), _logger);

      final result = await service.convertToBase(
        amount: 27,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isFalse);
      expect(result.data!.rateDate, DateTime(2026, 6, 1));
    });

    test('falls back to the nearest earlier rate, not the globally latest one', () async {
      final repo = FakeExchangeRateRepository([
        _usdRate(id: 'old', rate: 0.27, date: DateTime(2026, 1, 1)),
        _usdRate(id: 'future', rate: 0.30, date: DateTime(2026, 12, 1)),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(999), _logger);

      final result = await service.convertToBase(
        amount: 27,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 15),
      );

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isTrue);
      expect(result.data!.rateDate, DateTime(2026, 1, 1));
    });

    test('falls back to the live currency service when no stored rate exists', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository(),
        _StubCurrencyService(0.25),
        _logger,
      );

      final result = await service.convertToBase(
        amount: 25,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isTrue);
    });

    test('should return a typed failure instead of throwing for an unknown currency code', () async {
      final currencyService = _StubCurrencyService(0.25);
      final service = CurrencyConversionService(FakeExchangeRateRepository(), currencyService, _logger);

      final result = await service.convertToBase(
        amount: 10,
        fromCurrency: 'XYZ',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
      expect(currencyService.requestCount, 0);
    });

    test('should fall back to the live rate when stored rate lookups fail', () async {
      final service = CurrencyConversionService(
        FailingExchangeRateRepository(
          seed: [_usdRate(id: '1', rate: 0.5, date: DateTime(2026, 6, 1))],
          isLookupFailing: true,
        ),
        _StubCurrencyService(0.25),
        _logger,
      );

      final result = await service.convertToBase(
        amount: 25,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isTrue);
    });

    test('should ignore a non-positive stored rate instead of dividing by zero', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository([_usdRate(id: 'zero', rate: 0, date: DateTime(2026, 6, 1))]),
        _StubCurrencyService(0.25),
        _logger,
      );

      final result = await service.convertToBase(
        amount: 25,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isTrue);
    });

    test('should fail when the live rate is not positive', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository(),
        _StubCurrencyService(0),
        _logger,
      );

      final result = await service.convertToBase(
        amount: 25,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('CurrencyConversionService.convertToAccountCurrency', () {
    test('should convert between two non-base currencies through base', () async {
      final repo = FakeExchangeRateRepository([
        _usdRate(id: 'usd', rate: 0.25, date: DateTime(2026, 6, 1)),
        ExchangeRateModel(
          id: 'jod',
          fromCurrency: 'ILS',
          toCurrency: 'JOD',
          rate: 0.2,
          date: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(999), _logger);

      final result = await service.convertToAccountCurrency(
        amount: 10,
        fromCurrency: 'USD',
        toCurrency: 'JOD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(8, 0.001));
      expect(result.data!.rateUsed, closeTo(0.8, 0.001));
      expect(result.data!.wasFallback, isFalse);
    });

    test('should mark the result as fallback when either leg used a fallback rate', () async {
      final repo = FakeExchangeRateRepository([
        _usdRate(id: 'usd', rate: 0.25, date: DateTime(2026, 6, 1)),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(0.2), _logger);

      final result = await service.convertToAccountCurrency(
        amount: 10,
        fromCurrency: 'USD',
        toCurrency: 'JOD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(8, 0.001));
      expect(result.data!.wasFallback, isTrue);
    });

    test('should propagate the failure for an unknown target currency', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository([_usdRate(id: 'usd', rate: 0.25, date: DateTime(2026, 6, 1))]),
        _StubCurrencyService(0.2),
        _logger,
      );

      final result = await service.convertToAccountCurrency(
        amount: 10,
        fromCurrency: 'USD',
        toCurrency: 'XYZ',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
    });
  });
}
