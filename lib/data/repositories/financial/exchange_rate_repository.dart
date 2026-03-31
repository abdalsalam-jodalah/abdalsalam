import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../models/financial/exchange_rate_model.dart';

abstract class ExchangeRateRepository {
  Future<Result<ExchangeRateModel, Error>> create(ExchangeRateModel rate);
  Future<Result<ExchangeRateModel?, Error>> getById(String id);
  Future<Result<List<ExchangeRateModel>, Error>> getAll();
  Future<Result<ExchangeRateModel?, Error>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  );
  Future<Result<ExchangeRateModel?, Error>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  );
  Future<Result<List<ExchangeRateModel>, Error>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  );
  Future<Result<void, Error>> deleteOldRates(DateTime before);
}
