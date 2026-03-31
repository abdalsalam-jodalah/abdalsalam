import '../../../core/result/result.dart';
import '../../../core/errors/financial_errors.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../models/financial/exchange_rate_model.dart';
import 'exchange_rate_repository.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final StorageGateway _storage;
  final LoggerService _logger;

  static const String _tableName = 'exchange_rates';

  const ExchangeRateRepositoryImpl(this._storage, this._logger);

  @override
  Future<Result<ExchangeRateModel, Error>> create(ExchangeRateModel rate) async {
    try {
      await _storage.save(
        key: '${_tableName}_${rate.id}',
        value: rate.toJson(),
      );
      _logger.info('Exchange rate created: ${rate.fromCurrency} -> ${rate.toCurrency}');
      return Success(rate);
    } catch (e, st) {
      _logger.error('Failed to create exchange rate', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getById(String id) async {
    try {
      final data = await _storage.get<Map<String, dynamic>>('${_tableName}_$id');
      if (data == null) return Success(null);
      return Success(ExchangeRateModel.fromJson(data));
    } catch (e, st) {
      _logger.error('Failed to get exchange rate', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }

  @override
  Future<Result<List<ExchangeRateModel>, Error>> getAll() async {
    try {
      // This is a simplified implementation
      // In a real app, you'd query the database properly
      final allKeys = await _storage.getAllKeys();
      final rateKeys = allKeys.where((key) => key.startsWith(_tableName)).toList();

      final rates = <ExchangeRateModel>[];
      for (final key in rateKeys) {
        final data = await _storage.get<Map<String, dynamic>>(key);
        if (data != null) {
          rates.add(ExchangeRateModel.fromJson(data));
        }
      }

      return Success(rates);
    } catch (e, st) {
      _logger.error('Failed to get all exchange rates', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final rates = allResult.data!
          .where((r) =>
              r.fromCurrency == fromCurrency &&
              r.toCurrency == toCurrency &&
              r.deletedAt == null)
          .toList();

      if (rates.isEmpty) return Success(null);

      rates.sort((a, b) => b.date.compareTo(a.date));
      return Success(rates.first);
    } catch (e, st) {
      _logger.error('Failed to get latest rate', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final targetDate = DateTime(date.year, date.month, date.day);

      final rate = allResult.data!.firstWhere(
        (r) =>
            r.fromCurrency == fromCurrency &&
            r.toCurrency == toCurrency &&
            r.deletedAt == null &&
            DateTime(r.date.year, r.date.month, r.date.day) == targetDate,
        orElse: () => throw Exception('Rate not found'),
      );

      return Success(rate);
    } catch (e) {
      return Success(null);
    }
  }

  @override
  Future<Result<List<ExchangeRateModel>, Error>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final rates = allResult.data!
          .where((r) =>
              r.fromCurrency == fromCurrency &&
              r.toCurrency == toCurrency &&
              r.deletedAt == null &&
              r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              r.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();

      rates.sort((a, b) => a.date.compareTo(b.date));
      return Success(rates);
    } catch (e, st) {
      _logger.error('Failed to get rates for date range', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> deleteOldRates(DateTime before) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final oldRates = allResult.data!.where((r) => r.date.isBefore(before)).toList();

      for (final rate in oldRates) {
        await _storage.delete('${_tableName}_${rate.id}');
      }

      _logger.info('Deleted ${oldRates.length} old exchange rates');
      return Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete old rates', error: e, stackTrace: st);
      return Failure(FinancialError(e.toString()));
    }
  }
}
