import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/weather/weather_model.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../providers/app_providers.dart';
import '../../weather/services/weather_service.dart';
import '../../financial/providers/financial_providers.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

// Weather Service Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final logger = LoggerService.forModule(
    'WeatherService',
    moduleType: logic.ModuleType.service,
  );
  final storage = ref.watch(storageGatewayProvider);
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  return WeatherService(logger, storage, httpClient: httpClient);
});

// Weather Provider
final weatherProvider = FutureProvider<WeatherModel?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  final result = await service.getWeatherForNablus();
  return result.getOrThrow();
});

// Currency Rates Provider
final currencyRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(enhancedCurrencyServiceProvider);
  return await service.getLatestRates();
});

// USD History Provider (last 30 days)
final usdHistoryProvider = FutureProvider<List<ExchangeRateModel>>((ref) async {
  final service = ref.watch(enhancedCurrencyServiceProvider);
  return await service.getRatesHistory('ILS', 'USD', days: 30);
});

// JOD History Provider (last 30 days)
final jodHistoryProvider = FutureProvider<List<ExchangeRateModel>>((ref) async {
  final service = ref.watch(enhancedCurrencyServiceProvider);
  return await service.getRatesHistory('ILS', 'JOD', days: 30);
});
