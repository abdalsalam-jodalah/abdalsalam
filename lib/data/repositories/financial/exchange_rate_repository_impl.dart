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
      await _storage.upsertRecord(
        table: _tableName,
        id: rate.id,
        record: rate.toJson(),
      );
      _logger.info('Exchange rate created: ${rate.fromCurrency} -> ${rate.toCurrency}');
      return Success(rate);
    } catch (e, st) {
      _logger.error('Failed to create exchange rate', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getById(String id) async {
    try {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) return const Success(null);
      return Success(ExchangeRateModel.fromJson(record));
    } catch (e, st) {
      _logger.error('Failed to get exchange rate', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<List<ExchangeRateModel>, Error>> getAll() async {
    try {
      final records = await _storage.getAllRecords(table: _tableName);
      final rates = records
          .map(ExchangeRateModel.fromJson)
          .where((r) => r.deletedAt == null)
          .toList();
      return Success(rates);
    } catch (e, st) {
      _logger.error('Failed to get all exchange rates', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
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
          .where((r) => r.fromCurrency == fromCurrency && r.toCurrency == toCurrency)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return Success(rates.isEmpty ? null : rates.first);
    } catch (e, st) {
      _logger.error('Failed to get latest rate', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
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
      final matches = allResult.data!.where((r) =>
          r.fromCurrency == fromCurrency &&
          r.toCurrency == toCurrency &&
          DateTime(r.date.year, r.date.month, r.date.day) == targetDate);

      return Success(matches.isEmpty ? null : matches.first);
    } catch (e, st) {
      _logger.error('Failed to get rate for date', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateModel?, Error>> getNearestRateOnOrBefore(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final candidates = allResult.data!
          .where((r) =>
              r.fromCurrency == fromCurrency &&
              r.toCurrency == toCurrency &&
              !r.date.isAfter(endOfDay))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return Success(candidates.isEmpty ? null : candidates.first);
    } catch (e, st) {
      _logger.error('Failed to get nearest rate on or before date', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
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
              r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              r.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return Success(rates);
    } catch (e, st) {
      _logger.error('Failed to get rates for date range', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }

  @override
  Future<Result<void, Error>> deleteOldRates(DateTime before) async {
    try {
      final allResult = await getAll();
      if (allResult.isFailure) return Failure(allResult.error!);

      final oldRates = allResult.data!.where((r) => r.date.isBefore(before)).toList();
      for (final rate in oldRates) {
        await _storage.deleteRecord(table: _tableName, id: rate.id);
      }

      _logger.info('Deleted ${oldRates.length} old exchange rates');
      return const Success(null);
    } catch (e, st) {
      _logger.error('Failed to delete old rates', error: e, stackTrace: st);
      return Failure(DatabaseError(e.toString()));
    }
  }
}
