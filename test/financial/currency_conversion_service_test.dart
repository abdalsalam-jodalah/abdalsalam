import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/features/financial/services/currency_conversion_service.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Overrides the live-rate lookup so no HTTP call ever happens in tests.
class _StubCurrencyService extends CurrencyService {
  final double stubbedRate;

  _StubCurrencyService(this.stubbedRate)
      : super(LoggerService.forModule('test'), StorageGateway.instance);

  @override
  Future<double> getExchangeRate(Currency targetCurrency) async => stubbedRate;
}

void main() {
  group('CurrencyConversionService', () {
    test('same currency as base returns amount unchanged with rate 1.0', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository(),
        _StubCurrencyService(3.7),
      );

      final result = await service.convertToBase(
        amount: 100,
        fromCurrency: 'ILS',
        asOfDate: DateTime(2026, 1, 1),
      );

      expect(result.convertedAmount, 100);
      expect(result.rateUsed, 1.0);
      expect(result.wasFallback, isFalse);
    });

    test('uses the exact-date stored rate when available', () async {
      final repo = FakeExchangeRateRepository([
        ExchangeRateModel(
          id: '1',
          fromCurrency: 'ILS',
          toCurrency: 'USD',
          rate: 0.27, // 1 ILS = 0.27 USD
          date: DateTime(2026, 6, 1),
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(999));

      final result = await service.convertToBase(
        amount: 27,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.convertedAmount, closeTo(100, 0.001));
      expect(result.wasFallback, isFalse);
      expect(result.rateDate, DateTime(2026, 6, 1));
    });

    test('falls back to the nearest earlier rate, not the globally latest one', () async {
      final repo = FakeExchangeRateRepository([
        ExchangeRateModel(
          id: 'old',
          fromCurrency: 'ILS',
          toCurrency: 'USD',
          rate: 0.27,
          date: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ExchangeRateModel(
          id: 'future',
          fromCurrency: 'ILS',
          toCurrency: 'USD',
          rate: 0.30,
          date: DateTime(2026, 12, 1),
          createdAt: DateTime(2026, 12, 1),
          updatedAt: DateTime(2026, 12, 1),
        ),
      ]);
      final service = CurrencyConversionService(repo, _StubCurrencyService(999));

      // A transaction dated between the two stored rates should use the
      // earlier ("old") rate, never the later "future" one and never the
      // live stub.
      final result = await service.convertToBase(
        amount: 27,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 15),
      );

      expect(result.convertedAmount, closeTo(100, 0.001));
      expect(result.wasFallback, isTrue);
      expect(result.rateDate, DateTime(2026, 1, 1));
    });

    test('falls back to the live currency service when no stored rate exists', () async {
      final service = CurrencyConversionService(
        FakeExchangeRateRepository(),
        _StubCurrencyService(0.25), // 1 ILS = 0.25 USD
      );

      final result = await service.convertToBase(
        amount: 25,
        fromCurrency: 'USD',
        asOfDate: DateTime(2026, 6, 1),
      );

      expect(result.convertedAmount, closeTo(100, 0.001));
      expect(result.wasFallback, isTrue);
    });
  });
}
