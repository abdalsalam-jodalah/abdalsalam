import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/financial/exchange_rate_model.dart';
import 'package:abdalsalam/features/dashboard/providers/dashboard_providers.dart';
import 'package:abdalsalam/features/financial/providers/financial_providers.dart';
import 'package:abdalsalam/features/financial/services/currency_service.dart';
import 'package:abdalsalam/features/financial/services/enhanced_currency_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';

import '../financial/fakes.dart';

const _unreachableApiStatus = 503;
final _logger = LoggerService.forModule('DashboardProvidersTest');

/// A hand-written stub — not the real service's dependency chain, which
/// would need a live network. It's built on the real class so its public
/// surface can't drift silently, but overrides the two methods dashboard
/// providers call so their success/failure can be controlled directly.
class _StubEnhancedCurrencyService extends EnhancedCurrencyService {
  final Result<Map<String, double>, AppError> latestRatesResult;
  final Result<List<ExchangeRateModel>, AppError> ratesHistoryResult;

  _StubEnhancedCurrencyService({
    required this.latestRatesResult,
    required this.ratesHistoryResult,
  }) : super(
          FakeExchangeRateRepository(),
          _logger,
          CurrencyService(
            _logger,
            StorageGateway.instance,
            httpClient: MockClient((request) async => http.Response('unavailable', _unreachableApiStatus)),
          ),
        );

  @override
  Future<Result<Map<String, double>, AppError>> getLatestRates() async => latestRatesResult;

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getRatesHistory(
    String fromCurrency,
    String toCurrency, {
    int days = 30,
  }) async =>
      ratesHistoryResult;
}

ProviderContainer _buildContainer(_StubEnhancedCurrencyService service) {
  return ProviderContainer(overrides: [
    enhancedCurrencyServiceProvider.overrideWithValue(service),
  ]);
}

void main() {
  group('currencyRatesProvider', () {
    test('should return the latest rates on success', () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: const Success({'USD': 0.3, 'JOD': 0.2}),
        ratesHistoryResult: const Success([]),
      ));
      addTearDown(container.dispose);

      final result = await container.read(currencyRatesProvider.future);

      expect(result, {'USD': 0.3, 'JOD': 0.2});
    });

    test('should surface a service failure as AsyncError instead of an empty map', () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: Failure(NetworkError('rates unavailable')),
        ratesHistoryResult: const Success([]),
      ));
      addTearDown(container.dispose);

      await expectLater(
        container.read(currencyRatesProvider.future),
        throwsA(isA<NetworkError>()),
      );
    });
  });

  group('usdHistoryProvider / jodHistoryProvider', () {
    ExchangeRateModel rate(String toCurrency, double value) {
      final date = DateTime(2026, 6, 1);
      return ExchangeRateModel(
        id: '$toCurrency-${date.toIso8601String()}',
        fromCurrency: 'ILS',
        toCurrency: toCurrency,
        rate: value,
        date: date,
        createdAt: date,
        updatedAt: date,
      );
    }

    test('usdHistoryProvider should return the stored history on success', () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: const Success({}),
        ratesHistoryResult: Success([rate('USD', 0.3)]),
      ));
      addTearDown(container.dispose);

      final result = await container.read(usdHistoryProvider.future);

      expect(result, hasLength(1));
      expect(result.first.toCurrency, 'USD');
    });

    test('usdHistoryProvider should surface a service failure as AsyncError instead of an empty list',
        () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: const Success({}),
        ratesHistoryResult: Failure(DatabaseError('history lookup failed')),
      ));
      addTearDown(container.dispose);

      await expectLater(
        container.read(usdHistoryProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('jodHistoryProvider should return the stored history on success', () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: const Success({}),
        ratesHistoryResult: Success([rate('JOD', 0.2)]),
      ));
      addTearDown(container.dispose);

      final result = await container.read(jodHistoryProvider.future);

      expect(result, hasLength(1));
      expect(result.first.toCurrency, 'JOD');
    });

    test('jodHistoryProvider should surface a service failure as AsyncError instead of an empty list',
        () async {
      final container = _buildContainer(_StubEnhancedCurrencyService(
        latestRatesResult: const Success({}),
        ratesHistoryResult: Failure(DatabaseError('history lookup failed')),
      ));
      addTearDown(container.dispose);

      await expectLater(
        container.read(jodHistoryProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });
}
