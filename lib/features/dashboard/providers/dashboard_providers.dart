import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/weather/weather_model.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../providers/app_providers.dart';
import '../../weather/services/weather_service.dart';
import '../../financial/services/enhanced_currency_service.dart';
import '../../financial/services/currency_service.dart';
import '../../financial/providers/financial_providers.dart';
import '../../../data/repositories/financial/exchange_rate_repository.dart';
import '../../../data/repositories/financial/exchange_rate_repository_impl.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

// Weather Service Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final logger = LoggerService.forModule(
    'WeatherService',
    moduleType: logic.ModuleType.service,
  );
  final storage = ref.watch(storageGatewayProvider);
  final service = WeatherService(logger, storage);
  service.initialize();
  return service;
});

// Exchange Rate Repository Provider
final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  final logger = LoggerService.forModule(
    'ExchangeRateRepository',
    moduleType: logic.ModuleType.repository,
  );
  final storage = ref.watch(storageGatewayProvider);
  return ExchangeRateRepositoryImpl(storage, logger);
});

// Enhanced Currency Service Provider
final enhancedCurrencyServiceProvider = Provider<EnhancedCurrencyService>((ref) {
  final logger = LoggerService.forModule(
    'EnhancedCurrencyService',
    moduleType: logic.ModuleType.service,
  );
  final repository = ref.watch(exchangeRateRepositoryProvider);
  final currencyService = ref.watch(currencyServiceProvider);
  final service = EnhancedCurrencyService(repository, logger, currencyService);
  
  // Trigger daily sync on initialization
  service.syncDailyRates();
  
  return service;
});

// Weather Provider
final weatherProvider = FutureProvider<WeatherModel?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return await service.getWeatherForNablus();
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
