import 'dart:convert';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/errors/financial_errors.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/data/repositories/financial/exchange_rate_repository.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/features/financial/services/enhanced_currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

const _httpOk = 200;
const _httpServerError = 500;

final _logger = LoggerService.forModule('EnhancedCurrencyServiceTest');

class _CountingClient {
  int requestCount = 0;
  final String body;
  final int statusCode;

  _CountingClient(this.body, this.statusCode);

  http.Client build() {
    return MockClient((request) async {
      requestCount++;
      return http.Response(body, statusCode);
    });
  }
}

_CountingClient _ratesApi() {
  return _CountingClient(
    jsonEncode({
      'rates': {'USD': 0.27, 'JOD': 0.19},
    }),
    _httpOk,
  );
}

EnhancedCurrencyService _createService(ExchangeRateRepository repository, _CountingClient api) {
  final client = api.build();
  return EnhancedCurrencyService(
    repository,
    _logger,
    CurrencyService(_logger, StorageGateway.instance, httpClient: client),
    httpClient: client,
  );
}

ExchangeRateModel _storedUsdRate(DateTime date) {
  return ExchangeRateModel(
    id: 'usd-${date.toIso8601String()}',
    fromCurrency: 'ILS',
    toCurrency: 'USD',
    rate: 0.3,
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('EnhancedCurrencyService.syncDailyRates', () {
    test('should store one rate per target currency when the API responds', () async {
      final repository = FakeExchangeRateRepository();
      final service = _createService(repository, _ratesApi());

      final result = await service.syncDailyRates();

      expect(result.isSuccess, isTrue);
      expect(repository.rates.map((r) => r.toCurrency), unorderedEquals(['USD', 'JOD']));
    });

    test('should return failure when saving a fetched rate fails', () async {
      final repository = FailingExchangeRateRepository(isCreateFailing: true);
      final service = _createService(repository, _ratesApi());

      final result = await service.syncDailyRates();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
      expect(repository.rates, isEmpty);
    });

    test('should not fetch or create a rate when the existing-rate lookup fails', () async {
      final repository = FailingExchangeRateRepository(isLookupFailing: true);
      final api = _ratesApi();
      final service = _createService(repository, api);

      final result = await service.syncDailyRates();

      expect(result.isFailure, isTrue);
      expect(api.requestCount, 0);
      expect(repository.rates, isEmpty);
    });

    test('should return failure when the API fails', () async {
      final repository = FakeExchangeRateRepository();
      final service = _createService(repository, _CountingClient('', _httpServerError));

      final result = await service.syncDailyRates();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<NetworkError>());
      expect(repository.rates, isEmpty);
    });

    test('should return failure when the API response has no rates', () async {
      final repository = FakeExchangeRateRepository();
      final service = _createService(repository, _CountingClient(jsonEncode({'result': 'ok'}), _httpOk));

      final result = await service.syncDailyRates();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<CorruptDataError>());
    });

    test('should return failure when deleting old rates fails', () async {
      final repository = FailingExchangeRateRepository(isCleanupFailing: true);
      final service = _createService(repository, _ratesApi());

      final result = await service.syncDailyRates();

      expect(result.isFailure, isTrue);
      expect(repository.rates, hasLength(2));
    });
  });

  group('EnhancedCurrencyService.getRateForDate', () {
    test('should return the stored rate for the exact date as non-fallback', () async {
      final service = _createService(
        FakeExchangeRateRepository([_storedUsdRate(DateTime(2026, 6, 1))]),
        _ratesApi(),
      );

      final result = await service.getRateForDate('ILS', 'USD', DateTime(2026, 6, 1));

      expect(result.data!.rate, 0.3);
      expect(result.data!.isFallback, isFalse);
    });

    test('should flag the latest stored rate as fallback when the date has no rate', () async {
      final service = _createService(
        FakeExchangeRateRepository([_storedUsdRate(DateTime(2026, 6, 1))]),
        _ratesApi(),
      );

      final result = await service.getRateForDate('ILS', 'USD', DateTime(2026, 7, 1));

      expect(result.data!.rate, 0.3);
      expect(result.data!.isFallback, isTrue);
      expect(result.data!.fetchedAt, DateTime(2026, 6, 1));
    });

    test('should return a typed failure instead of throwing for an unknown currency code', () async {
      final service = _createService(FakeExchangeRateRepository(), _ratesApi());

      final result = await service.getRateForDate('ILS', 'XYZ', DateTime(2026, 6, 1));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
    });
  });

  group('EnhancedCurrencyService.convertWithHistoricalRate', () {
    test('should convert with the stored historical rate', () async {
      final service = _createService(
        FakeExchangeRateRepository([_storedUsdRate(DateTime(2026, 6, 1))]),
        _ratesApi(),
      );

      final result = await service.convertWithHistoricalRate(
        amount: 100,
        fromCurrency: 'ILS',
        toCurrency: 'USD',
        date: DateTime(2026, 6, 1),
      );

      expect(result.data!.convertedAmount, closeTo(30, 0.001));
      expect(result.data!.wasFallback, isFalse);
    });

    test('should return a typed failure instead of throwing for unknown currency codes', () async {
      final service = _createService(FakeExchangeRateRepository(), _ratesApi());

      final result = await service.convertWithHistoricalRate(
        amount: 100,
        fromCurrency: 'ABC',
        toCurrency: 'XYZ',
        date: DateTime(2026, 6, 1),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
    });
  });
}
