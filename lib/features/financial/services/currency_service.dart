import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';

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
  
  static const String _ratesKey = 'currency_rates';
  static const String _lastUpdateKey = 'currency_rates_last_update';
  
  // Base currency is ILS
  static const Currency baseCurrency = Currency.ils;
  
  // Cache exchange rates for 24 hours
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  Map<String, double> _cachedRates = {};
  DateTime? _lastUpdate;

  CurrencyService(this._logger, this._storage);

  /// Get exchange rate from base currency (ILS) to target currency
  Future<double> getExchangeRate(Currency targetCurrency) async {
    if (targetCurrency == baseCurrency) {
      return 1.0;
    }

    // Check if cache is valid
    if (_isCacheValid()) {
      final rate = _cachedRates[targetCurrency.code];
      if (rate != null) {
        _logger.info('Using cached exchange rate for ${targetCurrency.code}: $rate');
        return rate;
      }
    }

    // Fetch fresh rates
    await _fetchExchangeRates();
    
    return _cachedRates[targetCurrency.code] ?? 1.0;
  }

  /// Convert amount from one currency to another
  Future<double> convert({
    required double amount,
    required Currency from,
    required Currency to,
  }) async {
    if (from == to) {
      return amount;
    }

    // Convert to base currency (ILS) first
    double amountInBase = amount;
    if (from != baseCurrency) {
      final fromRate = await getExchangeRate(from);
      amountInBase = amount / fromRate;
    }

    // Convert from base to target currency
    if (to != baseCurrency) {
      final toRate = await getExchangeRate(to);
      return amountInBase * toRate;
    }

    return amountInBase;
  }

  /// Convert amount to base currency (ILS)
  Future<double> convertToBase(double amount, Currency from) async {
    return convert(amount: amount, from: from, to: baseCurrency);
  }

  /// Fetch exchange rates from API
  Future<void> _fetchExchangeRates() async {
    try {
      _logger.info('Fetching exchange rates from API');
      
      // Using exchangerate-api.com (free tier)
      // Base currency is ILS
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/ILS');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.warning('Exchange rate API timeout, using cached rates');
          return http.Response('{}', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;

        _cachedRates = {
          Currency.usd.code: (rates['USD'] as num?)?.toDouble() ?? 0.27,
          Currency.jod.code: (rates['JOD'] as num?)?.toDouble() ?? 0.19,
        };

        _lastUpdate = DateTime.now();

        // Save to storage
        await _saveRatesToStorage();

        _logger.info('Exchange rates updated: $_cachedRates');
      } else {
        _logger.warning('Failed to fetch exchange rates: ${response.statusCode}');
        await _loadRatesFromStorage();
      }
    } catch (e, st) {
      _logger.error('Error fetching exchange rates', error: e, stackTrace: st);
      await _loadRatesFromStorage();
    }
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

  /// Load rates from storage
  Future<void> _loadRatesFromStorage() async {
    try {
      final rates = await _storage.get<Map<String, dynamic>>(_ratesKey);
      final lastUpdateStr = await _storage.get<String>(_lastUpdateKey);

      if (rates != null) {
        _cachedRates = rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
        _logger.info('Loaded cached rates from storage: $_cachedRates');
      }

      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.parse(lastUpdateStr);
      }

      // If no cached rates, use fallback rates
      if (_cachedRates.isEmpty) {
        _cachedRates = {
          Currency.usd.code: 0.27, // Approximate ILS to USD
          Currency.jod.code: 0.19, // Approximate ILS to JOD
        };
        _logger.info('Using fallback exchange rates');
      }
    } catch (e, st) {
      _logger.error('Failed to load rates from storage', error: e, stackTrace: st);
      // Use fallback rates
      _cachedRates = {
        Currency.usd.code: 0.27,
        Currency.jod.code: 0.19,
      };
    }
  }

  /// Initialize the service (load cached rates)
  Future<void> initialize() async {
    await _loadRatesFromStorage();
    
    // Fetch fresh rates if cache is expired
    if (!_isCacheValid()) {
      await _fetchExchangeRates();
    }
  }

  /// Force refresh exchange rates
  Future<void> refreshRates() async {
    await _fetchExchangeRates();
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
