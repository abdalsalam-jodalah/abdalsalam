import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../models/financial/exchange_rate_model.dart';

abstract class ExchangeRateRepository {
  Future<Result<ExchangeRateModel, AppError>> create(ExchangeRateModel rate);
  Future<Result<ExchangeRateModel?, AppError>> getById(String id);
  Future<Result<List<ExchangeRateModel>, AppError>> getAll();
  Future<Result<ExchangeRateModel?, AppError>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  );
  Future<Result<ExchangeRateModel?, AppError>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  );
  Future<Result<List<ExchangeRateModel>, AppError>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  );

  /// Nearest stored rate on or before [date] — used for historical
  /// conversions so an old transaction never silently uses today's rate.
  Future<Result<ExchangeRateModel?, AppError>> getNearestRateOnOrBefore(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  );

  Future<Result<void, AppError>> deleteOldRates(DateTime before);
}
