import '../../../core/errors/app_error.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../core/result/result.dart';
import '../../../data/models/financial/exchange_rate_model.dart';
import '../../../data/repositories/financial/exchange_rate_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import 'conversion_result.dart';
import 'currency_service.dart';

/// Single source of truth for converting an amount into the app's base
/// currency. Every aggregation (summaries, category totals, budget spend,
/// net worth) must go through this instead of summing raw amounts, since
/// transactions can be recorded in different currencies.
///
/// Stored [ExchangeRateModel] rows are always base-currency -> target
/// currency (see [EnhancedCurrencyService.syncDailyRates]), so converting
/// TO base means inverting the stored rate.
class CurrencyConversionService {
  final ExchangeRateRepository _exchangeRateRepo;
  final CurrencyService _currencyService;
  final LoggerService _logger;

  static const String baseCurrencyCode = 'ILS';
  static const double _identityRate = 1.0;

  CurrencyConversionService(this._exchangeRateRepo, this._currencyService, this._logger);

  Future<Result<ConversionResult, AppError>> convertToBase({
    required double amount,
    required String fromCurrency,
    required DateTime asOfDate,
  }) async {
    if (fromCurrency == baseCurrencyCode) {
      return Success(_identityConversion(amount, asOfDate));
    }

    final exactRate = _usableStoredRate(
      await _exchangeRateRepo.getRateForDate(baseCurrencyCode, fromCurrency, asOfDate),
      fromCurrency: fromCurrency,
      lookupName: 'exact-date',
    );
    if (exactRate != null) {
      return Success(_convertWithStoredRate(amount, exactRate, wasFallback: false));
    }

    final nearestRate = _usableStoredRate(
      await _exchangeRateRepo.getNearestRateOnOrBefore(baseCurrencyCode, fromCurrency, asOfDate),
      fromCurrency: fromCurrency,
      lookupName: 'nearest-earlier',
    );
    if (nearestRate != null) {
      _logger.info(
        'No $fromCurrency rate stored for $asOfDate; using nearest earlier rate from ${nearestRate.date}',
      );
      return Success(_convertWithStoredRate(amount, nearestRate, wasFallback: true));
    }

    return _convertWithLiveRate(amount, fromCurrency);
  }

  ConversionResult _identityConversion(double amount, DateTime asOfDate) {
    return ConversionResult(
      convertedAmount: amount,
      rateUsed: _identityRate,
      rateDate: asOfDate,
      wasFallback: false,
    );
  }

  ExchangeRateModel? _usableStoredRate(
    Result<ExchangeRateModel?, AppError> lookupResult, {
    required String fromCurrency,
    required String lookupName,
  }) {
    if (lookupResult.isFailure) {
      _logger.warning('$lookupName $fromCurrency rate lookup failed: ${lookupResult.error}');
      return null;
    }
    final storedRate = lookupResult.data;
    if (storedRate == null) {
      return null;
    }
    if (storedRate.rate <= 0) {
      _logger.warning('Ignoring non-positive stored $fromCurrency rate ${storedRate.id}: ${storedRate.rate}');
      return null;
    }
    return storedRate;
  }

  ConversionResult _convertWithStoredRate(
    double amount,
    ExchangeRateModel storedRate, {
    required bool wasFallback,
  }) {
    return ConversionResult(
      convertedAmount: amount / storedRate.rate,
      rateUsed: _identityRate / storedRate.rate,
      rateDate: storedRate.date,
      wasFallback: wasFallback,
    );
  }

  Future<Result<ConversionResult, AppError>> _convertWithLiveRate(
    double amount,
    String fromCurrency,
  ) async {
    final currencyResult = CurrencyService.resolveCurrency(fromCurrency);
    if (currencyResult.isFailure) {
      _logger.warning('Cannot convert $fromCurrency to $baseCurrencyCode: ${currencyResult.error}');
      return Failure(currencyResult.error!);
    }

    final quoteResult = await _currencyService.getExchangeRate(currencyResult.data!);
    if (quoteResult.isFailure) {
      return Failure(quoteResult.error!);
    }

    final quote = quoteResult.data!;
    if (quote.rate <= 0) {
      return Failure(FinancialError('No usable exchange rate for $fromCurrency: ${quote.rate}'));
    }

    _logger.warning(
      'No stored $fromCurrency rate; using live rate ${quote.rate} (hard-coded or stale: ${quote.isFallback})',
    );
    return Success(ConversionResult(
      convertedAmount: amount / quote.rate,
      rateUsed: _identityRate / quote.rate,
      rateDate: quote.fetchedAt ?? DateTime.now(),
      wasFallback: true,
    ));
  }

  /// Converts between two arbitrary currencies by routing through base
  /// currency (base is the only currency stored rates are anchored to).
  Future<Result<ConversionResult, AppError>> convertToAccountCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,
  }) async {
    if (fromCurrency == toCurrency) {
      return Success(_identityConversion(amount, asOfDate));
    }

    final inBaseResult = await convertToBase(
      amount: amount,
      fromCurrency: fromCurrency,
      asOfDate: asOfDate,
    );
    if (inBaseResult.isFailure || toCurrency == baseCurrencyCode) {
      return inBaseResult;
    }

    final targetUnitResult = await convertToBase(
      amount: _identityRate,
      fromCurrency: toCurrency,
      asOfDate: asOfDate,
    );
    if (targetUnitResult.isFailure) {
      return Failure(targetUnitResult.error!);
    }

    final inBase = inBaseResult.data!;
    final targetUnit = targetUnitResult.data!;
    if (targetUnit.convertedAmount <= 0) {
      return Failure(FinancialError('No usable exchange rate for $toCurrency: ${targetUnit.rateUsed}'));
    }

    return Success(ConversionResult(
      convertedAmount: inBase.convertedAmount / targetUnit.convertedAmount,
      rateUsed: inBase.rateUsed / targetUnit.rateUsed,
      rateDate: inBase.rateDate.isBefore(targetUnit.rateDate) ? inBase.rateDate : targetUnit.rateDate,
      wasFallback: inBase.wasFallback || targetUnit.wasFallback,
    ));
  }
}
