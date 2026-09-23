import 'dart:convert';

import 'package:abdalsalam/core/errors/financial_errors.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storedRatesKey = 'currency_rates';
const _storedLastUpdateKey = 'currency_rates_last_update';
const _httpOk = 200;
const _httpServerError = 500;
const _fallbackIlsToUsdRate = 0.27;
const _fallbackIlsToJodRate = 0.19;

MockClient _respondingClient(String body, int statusCode) {
  return MockClient((request) async => http.Response(body, statusCode));
}

MockClient _failingClient() => _respondingClient('', _httpServerError);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storage = StorageGateway.instance;
  final logger = LoggerService.forModule('CurrencyServiceTest');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await storage.initialize(databaseName: 'test_currency_service_test.db');
    await storage.delete(_storedRatesKey);
    await storage.delete(_storedLastUpdateKey);
  });

  CurrencyService createService(http.Client client) {
    return CurrencyService(logger, storage, httpClient: client);
  }

  group('CurrencyService.getExchangeRate', () {
    test('should return a fresh non-fallback rate when the API responds', () async {
      final service = createService(_respondingClient(
        jsonEncode({
          'rates': {'USD': 0.3, 'JOD': 0.2},
        }),
        _httpOk,
      ));

      final result = await service.getExchangeRate(Currency.usd);

      expect(result.data!.rate, 0.3);
      expect(result.data!.isFallback, isFalse);
    });

    test('should return the hard-coded rate flagged as fallback when the API fails and nothing is stored', () async {
      final service = createService(_failingClient());

      final result = await service.getExchangeRate(Currency.usd);

      expect(result.data!.rate, _fallbackIlsToUsdRate);
      expect(result.data!.isFallback, isTrue);
    });

    test('should flag stale stored rates as fallback when the API fails', () async {
      await storage.save(key: _storedRatesKey, value: {'USD': 0.31, 'JOD': 0.21});
      await storage.save(
        key: _storedLastUpdateKey,
        value: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      );
      final service = createService(_failingClient());

      final result = await service.getExchangeRate(Currency.usd);

      expect(result.data!.rate, 0.31);
      expect(result.data!.isFallback, isTrue);
    });

    test('should use the hard-coded fallback when the API response has no usable rate', () async {
      final service = createService(_respondingClient(
        jsonEncode({
          'rates': {'USD': 'not-a-number', 'JOD': 0.2},
        }),
        _httpOk,
      ));

      final usdResult = await service.getExchangeRate(Currency.usd);
      final jodResult = await service.getExchangeRate(Currency.jod);

      expect(usdResult.data!.rate, _fallbackIlsToUsdRate);
      expect(usdResult.data!.isFallback, isTrue);
      expect(jodResult.data!.rate, 0.2);
      expect(jodResult.data!.isFallback, isFalse);
    });

    test('should not throw when the API returns malformed JSON', () async {
      final service = createService(_respondingClient('not json', _httpOk));

      final result = await service.getExchangeRate(Currency.jod);

      expect(result.data!.rate, _fallbackIlsToJodRate);
      expect(result.data!.isFallback, isTrue);
    });
  });

  group('CurrencyService.initialize', () {
    test('should ignore corrupt stored rates and an unreadable update time without throwing', () async {
      await storage.save(key: _storedRatesKey, value: 'garbage');
      await storage.save(key: _storedLastUpdateKey, value: 'not-a-date');
      final service = createService(_failingClient());

      final initializeResult = await service.initialize();
      final rateResult = await service.getExchangeRate(Currency.usd);

      expect(initializeResult.isFailure, isTrue);
      expect(service.getLastUpdateTime(), isNull);
      expect(rateResult.data!.rate, _fallbackIlsToUsdRate);
      expect(rateResult.data!.isFallback, isTrue);
    });

    test('should succeed and persist rates when the API responds', () async {
      final service = createService(_respondingClient(
        jsonEncode({
          'rates': {'USD': 0.3, 'JOD': 0.2},
        }),
        _httpOk,
      ));

      final result = await service.initialize();

      expect(result.isSuccess, isTrue);
      expect(await storage.get<Map<String, dynamic>>(_storedRatesKey), {'USD': 0.3, 'JOD': 0.2});
    });
  });

  group('CurrencyService.convert', () {
    test('should mark the conversion as fallback when a hard-coded rate was used', () async {
      final service = createService(_failingClient());

      final result = await service.convert(amount: 27, from: Currency.usd, to: Currency.ils);

      expect(result.data!.convertedAmount, closeTo(100, 0.001));
      expect(result.data!.wasFallback, isTrue);
    });

    test('should not mark the conversion as fallback when fresh rates were used', () async {
      final service = createService(_respondingClient(
        jsonEncode({
          'rates': {'USD': 0.25, 'JOD': 0.2},
        }),
        _httpOk,
      ));

      final result = await service.convert(amount: 10, from: Currency.usd, to: Currency.jod);

      expect(result.data!.convertedAmount, closeTo(8, 0.001));
      expect(result.data!.wasFallback, isFalse);
    });
  });

  group('CurrencyService.resolveCurrency', () {
    test('should resolve a known currency code', () {
      final result = CurrencyService.resolveCurrency('JOD');

      expect(result.data, Currency.jod);
    });

    test('should return a typed failure for an unknown currency code', () {
      final result = CurrencyService.resolveCurrency('XYZ');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<FinancialError>());
    });
  });
}
