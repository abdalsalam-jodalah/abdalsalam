import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../data/repositories/financial/exchange_rate_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import 'currency_service.dart';

class EnhancedCurrencyService {
  final ExchangeRateRepository _repository;
  final LoggerService _logger;
  final CurrencyService _currencyService;

  static const String _baseCurrency = 'ILS';
  static const List<String> _targetCurrencies = ['USD', 'JOD'];

  EnhancedCurrencyService(
    this._repository,
    this._logger,
    this._currencyService,
  );

  /// Sync exchange rates daily
  Future<Result<void, Error>> syncDailyRates() async {
    try {
      _logger.info('Starting daily exchange rate sync');

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Check if we already have rates for today
      for (final targetCurrency in _targetCurrencies) {
        final existingRate = await _repository.getRateForDate(
          _baseCurrency,
          targetCurrency,
          todayDate,
        );

        if (existingRate.isSuccess && existingRate.data != null) {
          _logger.info('Rate already exists for $targetCurrency today');
          continue;
        }

        // Fetch fresh rate
        final rate = await _fetchRateFromAPI(_baseCurrency, targetCurrency);
        if (rate != null) {
          final rateModel = ExchangeRateModel(
            id: const Uuid().v4(),
            fromCurrency: _baseCurrency,
            toCurrency: targetCurrency,
            rate: rate,
            date: todayDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _repository.create(rateModel);
          _logger.info('Saved rate: $_baseCurrency -> $targetCurrency = $rate');
        }
      }

      // Clean up old rates (keep last 90 days)
      final cutoffDate = today.subtract(const Duration(days: 90));
      await _repository.deleteOldRates(cutoffDate);

      _logger.info('Daily exchange rate sync completed');
      return Success(null);
    } catch (e, st) {
      _logger.error('Failed to sync daily rates', error: e, stackTrace: st);
      return Failure(StateError(e.toString()));
    }
  }

  /// Fetch rate from API
  Future<double?> _fetchRateFromAPI(String from, String to) async {
    try {
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$from');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        return (rates[to] as num?)?.toDouble();
      }
    } catch (e) {
      _logger.error('Failed to fetch rate from API', error: e);
    }
    return null;
  }

  /// Get rate for specific date (from database)
  Future<double?> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    final result = await _repository.getRateForDate(
      fromCurrency,
      toCurrency,
      date,
    );

    if (result.isSuccess && result.data != null) {
      return result.data!.rate;
    }

    // Fallback to latest rate
    final latestResult = await _repository.getLatestRate(
      fromCurrency,
      toCurrency,
    );

    if (latestResult.isSuccess && latestResult.data != null) {
      return latestResult.data!.rate;
    }

    // Fallback to currency service
    return await _currencyService.getExchangeRate(
      Currency.values.firstWhere((c) => c.code == toCurrency),
    );
  }

  /// Get all rates for a currency pair
  Future<List<ExchangeRateModel>> getRatesHistory(
    String fromCurrency,
    String toCurrency, {
    int days = 30,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));

    final result = await _repository.getRatesForDateRange(
      fromCurrency,
      toCurrency,
      start,
      end,
    );

    if (result.isSuccess) {
      return result.data!;
    }

    return [];
  }

  /// Get latest rates for all currencies
  Future<Map<String, double>> getLatestRates() async {
    final rates = <String, double>{};

    for (final currency in _targetCurrencies) {
      final result = await _repository.getLatestRate(_baseCurrency, currency);
      if (result.isSuccess && result.data != null) {
        rates[currency] = result.data!.rate;
      }
    }

    return rates;
  }

  /// Convert amount using historical rate
  Future<double> convertWithHistoricalRate({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    final rate = await getRateForDate(fromCurrency, toCurrency, date);
    if (rate != null) {
      return amount * rate;
    }

    // Fallback to current rate
    return await _currencyService.convert(
      amount: amount,
      from: Currency.values.firstWhere((c) => c.code == fromCurrency),
      to: Currency.values.firstWhere((c) => c.code == toCurrency),
    );
  }
}
