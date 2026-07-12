import '../../../data/repositories/financial/exchange_rate_repository.dart';
import 'currency_service.dart';

class ConversionResult {
  final double convertedAmount;
  final double rateUsed;
  final DateTime rateDate;
  final bool wasFallback;

  const ConversionResult({
    required this.convertedAmount,
    required this.rateUsed,
    required this.rateDate,
    required this.wasFallback,
  });
}

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

  static const String baseCurrencyCode = 'ILS';

  CurrencyConversionService(this._exchangeRateRepo, this._currencyService);

  Future<ConversionResult> convertToBase({
    required double amount,
    required String fromCurrency,
    required DateTime asOfDate,
  }) async {
    if (fromCurrency == baseCurrencyCode) {
      return ConversionResult(
        convertedAmount: amount,
        rateUsed: 1.0,
        rateDate: asOfDate,
        wasFallback: false,
      );
    }

    final exactResult = await _exchangeRateRepo.getRateForDate(
      baseCurrencyCode,
      fromCurrency,
      asOfDate,
    );
    if (exactResult.isSuccess && exactResult.data != null) {
      final rate = exactResult.data!;
      return ConversionResult(
        convertedAmount: amount / rate.rate,
        rateUsed: 1 / rate.rate,
        rateDate: rate.date,
        wasFallback: false,
      );
    }

    final nearestResult = await _exchangeRateRepo.getNearestRateOnOrBefore(
      baseCurrencyCode,
      fromCurrency,
      asOfDate,
    );
    if (nearestResult.isSuccess && nearestResult.data != null) {
      final rate = nearestResult.data!;
      return ConversionResult(
        convertedAmount: amount / rate.rate,
        rateUsed: 1 / rate.rate,
        rateDate: rate.date,
        wasFallback: true,
      );
    }

    final liveRate = await _currencyService.getExchangeRate(
      Currency.values.firstWhere((c) => c.code == fromCurrency),
    );
    return ConversionResult(
      convertedAmount: liveRate == 0 ? amount : amount / liveRate,
      rateUsed: liveRate == 0 ? 1.0 : 1 / liveRate,
      rateDate: DateTime.now(),
      wasFallback: true,
    );
  }

  /// Converts between two arbitrary currencies by routing through base
  /// currency (base is the only currency stored rates are anchored to).
  Future<double> convertToAccountCurrency({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }
    final inBase = await convertToBase(
      amount: amount,
      fromCurrency: fromCurrency,
      asOfDate: asOfDate,
    );
    if (toCurrency == baseCurrencyCode) {
      return inBase.convertedAmount;
    }
    final toBaseRate = await convertToBase(
      amount: 1,
      fromCurrency: toCurrency,
      asOfDate: asOfDate,
    );
    if (toBaseRate.convertedAmount == 0) {
      return inBase.convertedAmount;
    }
    return inBase.convertedAmount / toBaseRate.convertedAmount;
  }
}
