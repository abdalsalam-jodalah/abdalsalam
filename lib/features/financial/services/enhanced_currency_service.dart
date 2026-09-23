import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../data/repositories/financial/exchange_rate_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'conversion_result.dart';
import 'currency_service.dart';
import 'exchange_rate_quote.dart';

class EnhancedCurrencyService {
  final ExchangeRateRepository _repository;
  final LoggerService _logger;
  final CurrencyService _currencyService;
  final http.Client _httpClient;
  final ErrorHandler _errorHandler;

  static const String _baseCurrency = 'ILS';
  static const List<String> _targetCurrencies = ['USD', 'JOD'];
  static const String _ratesApiBaseUrl = 'https://api.exchangerate-api.com/v4/latest/';
  static const String _ratesApiField = 'rates';
  static const String _ratesApiSource = 'exchangerate-api';
  static const Duration _apiTimeout = Duration(seconds: 10);
  static const int _httpStatusOk = 200;
  static const Duration _rateRetention = Duration(days: 90);
  static const double _identityRate = 1.0;

  EnhancedCurrencyService(
    this._repository,
    this._logger,
    this._currencyService, {
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _errorHandler = ErrorHandler(_logger);

  /// Sync exchange rates daily
  Future<Result<void, AppError>> syncDailyRates() async {
    try {
      _logger.info('Starting daily exchange rate sync');

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      AppError? firstFailure;

      for (final targetCurrency in _targetCurrencies) {
        final syncResult = await _syncRate(targetCurrency, todayDate);
        if (syncResult.isFailure) {
          _logger.warning('Exchange rate sync failed for $targetCurrency: ${syncResult.error}');
          firstFailure ??= syncResult.error;
        }
      }

      final cutoffDate = today.subtract(_rateRetention);
      final cleanupResult = await _repository.deleteOldRates(cutoffDate);
      if (cleanupResult.isFailure) {
        _logger.warning('Failed to delete exchange rates older than $cutoffDate: ${cleanupResult.error}');
        firstFailure ??= cleanupResult.error;
      }

      if (firstFailure != null) {
        return Failure(firstFailure);
      }
      _logger.info('Daily exchange rate sync completed');
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(
        e,
        context: 'EnhancedCurrencyService.syncDailyRates',
        stackTrace: st,
      ));
    }
  }

  Future<Result<void, AppError>> _syncRate(String targetCurrency, DateTime todayDate) async {
    final existingRate = await _repository.getRateForDate(_baseCurrency, targetCurrency, todayDate);
    if (existingRate.isFailure) {
      return Failure(existingRate.error!);
    }
    if (existingRate.data != null) {
      _logger.info('Rate already exists for $targetCurrency today');
      return const Success(null);
    }

    final rateResult = await _fetchRateFromAPI(_baseCurrency, targetCurrency);
    if (rateResult.isFailure) {
      return Failure(rateResult.error!);
    }

    final rate = rateResult.data!;
    final rateModel = ExchangeRateModel(
      id: const Uuid().v4(),
      fromCurrency: _baseCurrency,
      toCurrency: targetCurrency,
      rate: rate,
      date: todayDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final createResult = await _repository.create(rateModel);
    if (createResult.isFailure) {
      return Failure(createResult.error!);
    }
    _logger.info('Saved rate: $_baseCurrency -> $targetCurrency = $rate');
    return const Success(null);
  }

  Future<Result<double, AppError>> _fetchRateFromAPI(String from, String to) async {
    try {
      final url = Uri.parse('$_ratesApiBaseUrl$from');
      final response = await _httpClient.get(url).timeout(_apiTimeout);

      if (response.statusCode != _httpStatusOk) {
        return Failure(NetworkError('Exchange rate API returned status ${response.statusCode}'));
      }

      final decoded = jsonDecode(response.body);
      final rates = decoded is Map<String, dynamic> ? decoded[_ratesApiField] : null;
      if (rates is! Map<String, dynamic>) {
        return Failure(CorruptDataError(
          'Exchange rate API response has no rates',
          source: _ratesApiSource,
          field: _ratesApiField,
        ));
      }

      final rate = JsonReader(rates, source: _ratesApiSource).optionalDouble(to);
      if (rate == null || rate <= 0) {
        return Failure(CorruptDataError(
          'Exchange rate API response has no usable rate for $to',
          source: _ratesApiSource,
          field: to,
        ));
      }
      return Success(rate);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(
        e,
        context: 'EnhancedCurrencyService.fetchRateFromAPI',
        stackTrace: st,
      ));
    }
  }

  /// Get rate for specific date (from database)
  Future<Result<ExchangeRateQuote, AppError>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    final result = await _repository.getRateForDate(
      fromCurrency,
      toCurrency,
      date,
    );
    if (result.isFailure) {
      _logger.warning('Stored $fromCurrency -> $toCurrency rate lookup for $date failed: ${result.error}');
    } else if (result.data != null) {
      return Success(ExchangeRateQuote(rate: result.data!.rate, fetchedAt: result.data!.date, isFallback: false));
    }

    final latestResult = await _repository.getLatestRate(
      fromCurrency,
      toCurrency,
    );
    if (latestResult.isFailure) {
      _logger.warning('Latest $fromCurrency -> $toCurrency rate lookup failed: ${latestResult.error}');
    } else if (latestResult.data != null) {
      final latest = latestResult.data!;
      _logger.info('No $fromCurrency -> $toCurrency rate for $date; falling back to latest from ${latest.date}');
      return Success(ExchangeRateQuote(rate: latest.rate, fetchedAt: latest.date, isFallback: true));
    }

    final currencyResult = CurrencyService.resolveCurrency(toCurrency);
    if (currencyResult.isFailure) {
      return Failure(currencyResult.error!);
    }
    final liveResult = await _currencyService.getExchangeRate(currencyResult.data!);
    if (liveResult.isFailure) {
      return Failure(liveResult.error!);
    }
    final live = liveResult.data!;
    _logger.warning('No stored $fromCurrency -> $toCurrency rate; falling back to live rate ${live.rate}');
    return Success(ExchangeRateQuote(rate: live.rate, fetchedAt: live.fetchedAt, isFallback: true));
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

    _logger.warning('Failed to load $fromCurrency -> $toCurrency rate history: ${result.error}');
    return [];
  }

  /// Get latest rates for all currencies
  Future<Map<String, double>> getLatestRates() async {
    final rates = <String, double>{};

    for (final currency in _targetCurrencies) {
      final result = await _repository.getLatestRate(_baseCurrency, currency);
      if (result.isFailure) {
        _logger.warning('Failed to load latest $_baseCurrency -> $currency rate: ${result.error}');
      } else if (result.data != null) {
        rates[currency] = result.data!.rate;
      }
    }

    return rates;
  }

  /// Convert amount using historical rate
  Future<Result<ConversionResult, AppError>> convertWithHistoricalRate({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
  }) async {
    if (fromCurrency == toCurrency) {
      return Success(ConversionResult(
        convertedAmount: amount,
        rateUsed: _identityRate,
        rateDate: date,
        wasFallback: false,
      ));
    }

    final quoteResult = await getRateForDate(fromCurrency, toCurrency, date);
    if (quoteResult.isSuccess) {
      final quote = quoteResult.data!;
      return Success(ConversionResult(
        convertedAmount: amount * quote.rate,
        rateUsed: quote.rate,
        rateDate: quote.fetchedAt ?? date,
        wasFallback: quote.isFallback,
      ));
    }

    _logger.warning('Historical $fromCurrency -> $toCurrency rate unavailable: ${quoteResult.error}');
    final fromResult = CurrencyService.resolveCurrency(fromCurrency);
    if (fromResult.isFailure) {
      return Failure(fromResult.error!);
    }
    final toResult = CurrencyService.resolveCurrency(toCurrency);
    if (toResult.isFailure) {
      return Failure(toResult.error!);
    }
    final currentResult = await _currencyService.convert(
      amount: amount,
      from: fromResult.data!,
      to: toResult.data!,
    );
    return currentResult.map((current) => ConversionResult(
          convertedAmount: current.convertedAmount,
          rateUsed: current.rateUsed,
          rateDate: current.rateDate,
          wasFallback: true,
        ));
  }
}
