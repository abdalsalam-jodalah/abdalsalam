import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/errors/app_error.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../shared/services/error_handler.dart';
import 'conversion_result.dart';
import 'exchange_rate_quote.dart';

enum Currency {
  ils('ILS', '₪', 'Israeli Shekel'),
  usd('USD', '\$', 'US Dollar'),
  jod('JOD', 'JD', 'Jordanian Dinar');

  final String code;
  final String symbol;
  final String name;

  const Currency(this.code, this.symbol, this.name);
}

class CurrencyService {
  final LoggerService _logger;
  final StorageGateway _storage;
  final http.Client _httpClient;
  final ErrorHandler _errorHandler;

  static const String _ratesKey = 'currency_rates';
  static const String _lastUpdateKey = 'currency_rates_last_update';
  static const String _ratesApiUrl = 'https://api.exchangerate-api.com/v4/latest/ILS';
  static const String _ratesApiField = 'rates';
  static const String _ratesApiSource = 'exchangerate-api';
  static const Duration _apiTimeout = Duration(seconds: 10);
  static const int _httpStatusOk = 200;

  static const Currency baseCurrency = Currency.ils;
  static const double _baseRate = 1.0;
  static const double _fallbackIlsToUsdRate = 0.27;
  static const double _fallbackIlsToJodRate = 0.19;

  static const Duration _cacheExpiry = Duration(hours: 24);

  Map<String, double> _cachedRates = {};
  DateTime? _lastUpdate;

  CurrencyService(this._logger, this._storage, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _errorHandler = ErrorHandler(_logger);

  static Result<Currency, AppError> resolveCurrency(String code) {
    for (final currency in Currency.values) {
      if (currency.code == code) {
        return Success(currency);
      }
    }
    return Failure(FinancialError('Unsupported currency code: $code'));
  }

  /// Get exchange rate from base currency (ILS) to target currency
  Future<Result<ExchangeRateQuote, AppError>> getExchangeRate(Currency targetCurrency) async {
    if (targetCurrency == baseCurrency) {
      return Success(ExchangeRateQuote(rate: _baseRate, fetchedAt: DateTime.now(), isFallback: false));
    }
    try {
      if (!_isCacheValid() || !_cachedRates.containsKey(targetCurrency.code)) {
        final refreshResult = await _fetchExchangeRates();
        if (refreshResult.isFailure) {
          _logger.warning('Exchange rate refresh failed for ${targetCurrency.code}: ${refreshResult.error}');
        }
      }

      final cachedRate = _cachedRates[targetCurrency.code];
      if (cachedRate == null) {
        return Success(_hardCodedFallbackQuote(targetCurrency));
      }

      final isStale = !_isCacheValid();
      if (isStale) {
        _logger.warning(
          'Using stale stored exchange rate for ${targetCurrency.code}: $cachedRate (last update: $_lastUpdate)',
        );
      }
      return Success(ExchangeRateQuote(rate: cachedRate, fetchedAt: _lastUpdate, isFallback: isStale));
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(
        error,
        context: 'CurrencyService.getExchangeRate',
        stackTrace: stackTrace,
      ));
    }
  }

  ExchangeRateQuote _hardCodedFallbackQuote(Currency targetCurrency) {
    final rate = _hardCodedRateFor(targetCurrency);
    _logger.warning('Using hard-coded fallback exchange rate for ${targetCurrency.code}: $rate');
    return ExchangeRateQuote(rate: rate, fetchedAt: null, isFallback: true);
  }

  static double _hardCodedRateFor(Currency currency) {
    return switch (currency) {
      Currency.ils => _baseRate,
      Currency.usd => _fallbackIlsToUsdRate,
      Currency.jod => _fallbackIlsToJodRate,
    };
  }

  /// Convert amount from one currency to another
  Future<Result<ConversionResult, AppError>> convert({
    required double amount,
    required Currency from,
    required Currency to,
  }) async {
    if (from == to) {
      return Success(ConversionResult(
        convertedAmount: amount,
        rateUsed: _baseRate,
        rateDate: DateTime.now(),
        wasFallback: false,
      ));
    }

    final fromQuoteResult = await getExchangeRate(from);
    if (fromQuoteResult.isFailure) {
      return Failure(fromQuoteResult.error!);
    }
    final toQuoteResult = await getExchangeRate(to);
    if (toQuoteResult.isFailure) {
      return Failure(toQuoteResult.error!);
    }

    final fromQuote = fromQuoteResult.data!;
    final toQuote = toQuoteResult.data!;
    final rateUsed = toQuote.rate / fromQuote.rate;
    return Success(ConversionResult(
      convertedAmount: amount * rateUsed,
      rateUsed: rateUsed,
      rateDate: fromQuote.fetchedAt ?? toQuote.fetchedAt ?? DateTime.now(),
      wasFallback: fromQuote.isFallback || toQuote.isFallback,
    ));
  }

  /// Convert amount to base currency (ILS)
  Future<Result<ConversionResult, AppError>> convertToBase(double amount, Currency from) async {
    return convert(amount: amount, from: from, to: baseCurrency);
  }

  Future<Result<void, AppError>> _fetchExchangeRates() async {
    try {
      _logger.info('Fetching exchange rates from API');
      final response = await _httpClient.get(Uri.parse(_ratesApiUrl)).timeout(_apiTimeout);

      if (response.statusCode != _httpStatusOk) {
        _logger.warning('Failed to fetch exchange rates: ${response.statusCode}, using stored rates');
        await _loadRatesFromStorage();
        return Failure(NetworkError('Exchange rate API returned status ${response.statusCode}'));
      }

      final fetchedRates = _parseApiRates(response.body);
      if (fetchedRates.isEmpty) {
        _logger.warning('Exchange rate API response had no usable rates, using stored rates');
        await _loadRatesFromStorage();
        return Failure(CorruptDataError(
          'Exchange rate API response had no usable rates',
          source: _ratesApiSource,
          field: _ratesApiField,
        ));
      }

      _cachedRates = fetchedRates;
      _lastUpdate = DateTime.now();
      await _saveRatesToStorage();
      _logger.info('Exchange rates updated: $_cachedRates');
      return const Success(null);
    } catch (error, stackTrace) {
      final mappedError = _errorHandler.mapException(
        error,
        context: 'CurrencyService.fetchExchangeRates',
        stackTrace: stackTrace,
      );
      await _loadRatesFromStorage();
      return Failure(mappedError);
    }
  }

  Map<String, double> _parseApiRates(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }
    final rates = decoded[_ratesApiField];
    if (rates is! Map<String, dynamic>) {
      return {};
    }
    return _ratesFromJson(rates, source: _ratesApiSource);
  }

  Map<String, double> _ratesFromJson(Map<String, dynamic> json, {required String source}) {
    final reader = JsonReader(json, source: source);
    final rates = <String, double>{};
    for (final currency in Currency.values) {
      if (currency == baseCurrency) {
        continue;
      }
      final rate = reader.optionalDouble(currency.code);
      if (rate != null && rate > 0) {
        rates[currency.code] = rate;
      }
    }
    return rates;
  }

  /// Check if cached rates are still valid
  bool _isCacheValid() {
    if (_lastUpdate == null || _cachedRates.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(_lastUpdate!);

    return difference < _cacheExpiry;
  }

  /// Save rates to storage
  Future<void> _saveRatesToStorage() async {
    try {
      await _storage.save(
        key: _ratesKey,
        value: _cachedRates,
      );
      await _storage.save(
        key: _lastUpdateKey,
        value: _lastUpdate?.toIso8601String(),
      );
    } catch (e, st) {
      _logger.error('Failed to save rates to storage', error: e, stackTrace: st);
    }
  }

  Future<void> _loadRatesFromStorage() async {
    final storedRates = await _readStoredRates();
    if (storedRates.isNotEmpty) {
      _cachedRates = storedRates;
      _logger.info('Loaded cached rates from storage: $_cachedRates');
    }

    final storedLastUpdate = await _readStoredLastUpdate();
    if (storedLastUpdate != null) {
      _lastUpdate = storedLastUpdate;
    }
  }

  Future<Map<String, double>> _readStoredRates() async {
    try {
      final stored = await _storage.get<Object>(_ratesKey);
      if (stored == null) {
        return {};
      }
      if (stored is! Map<String, dynamic>) {
        _logger.warning('Ignoring stored exchange rates with unexpected type ${stored.runtimeType}');
        return {};
      }
      return _ratesFromJson(stored, source: _ratesKey);
    } catch (e, st) {
      _logger.error('Failed to load rates from storage', error: e, stackTrace: st);
      return {};
    }
  }

  Future<DateTime?> _readStoredLastUpdate() async {
    try {
      final stored = await _storage.get<Object>(_lastUpdateKey);
      if (stored == null) {
        return null;
      }
      final parsed = stored is String ? DateTime.tryParse(stored) : null;
      if (parsed == null) {
        _logger.warning('Ignoring unreadable stored exchange rate update time: $stored');
      }
      return parsed;
    } catch (e, st) {
      _logger.error('Failed to load exchange rate update time from storage', error: e, stackTrace: st);
      return null;
    }
  }

  /// Initialize the service (load cached rates)
  Future<Result<void, AppError>> initialize() async {
    await _loadRatesFromStorage();
    if (_isCacheValid()) {
      return const Success(null);
    }
    return _fetchExchangeRates();
  }

  /// Force refresh exchange rates
  Future<Result<void, AppError>> refreshRates() {
    return _fetchExchangeRates();
  }

  /// Get all current rates
  Map<String, double> getCurrentRates() {
    return Map.unmodifiable(_cachedRates);
  }

  /// Get last update time
  DateTime? getLastUpdateTime() {
    return _lastUpdate;
  }

  /// Format amount with currency symbol
  String formatAmount(double amount, Currency currency) {
    return '${currency.symbol}${amount.toStringAsFixed(2)}';
  }
}
