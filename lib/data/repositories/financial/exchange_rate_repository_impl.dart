import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../models/financial/exchange_rate_model.dart';
import '../record_parser.dart';
import '../repository_operation_guard.dart';
import 'exchange_rate_repository.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final StorageGateway _storage;
  final LoggerService _logger;

  static const String _tableName = 'exchange_rates';

  const ExchangeRateRepositoryImpl(this._storage, this._logger);

  RepositoryOperationGuard get _guard => RepositoryOperationGuard(table: _tableName, logger: _logger);

  RecordParser<ExchangeRateModel> get _parser => RecordParser<ExchangeRateModel>(
        table: _tableName,
        fromJson: ExchangeRateModel.fromJson,
        integrityReporter: _storage.integrityReporter,
      );

  @override
  Future<Result<ExchangeRateModel, AppError>> create(ExchangeRateModel rate) {
    return _guard.run('create', () async {
      await _storage.upsertRecord(
        table: _tableName,
        id: rate.id,
        record: rate.toJson(),
      );
      _logger.info('Exchange rate created: ${rate.fromCurrency} -> ${rate.toCurrency}');
      return rate;
    });
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getById(String id) {
    return _guard.run('getById', () async {
      final record = await _storage.getRecord(table: _tableName, id: id);
      if (record == null) return null;
      return _parser.parseOne(record);
    });
  }

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getAll() {
    return _guard.run('getAll', _readAll);
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getLatestRate(
    String fromCurrency,
    String toCurrency,
  ) {
    return _guard.run('getLatestRate', () async {
      final rates = (await _readAll())
          .where((r) => r.fromCurrency == fromCurrency && r.toCurrency == toCurrency)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return rates.isEmpty ? null : rates.first;
    });
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getRateForDate(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) {
    return _guard.run('getRateForDate', () async {
      final targetDate = DateTime(date.year, date.month, date.day);
      final matches = (await _readAll()).where((r) =>
          r.fromCurrency == fromCurrency &&
          r.toCurrency == toCurrency &&
          DateTime(r.date.year, r.date.month, r.date.day) == targetDate);

      return matches.isEmpty ? null : matches.first;
    });
  }

  @override
  Future<Result<ExchangeRateModel?, AppError>> getNearestRateOnOrBefore(
    String fromCurrency,
    String toCurrency,
    DateTime date,
  ) {
    return _guard.run('getNearestRateOnOrBefore', () async {
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final candidates = (await _readAll())
          .where((r) =>
              r.fromCurrency == fromCurrency &&
              r.toCurrency == toCurrency &&
              !r.date.isAfter(endOfDay))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return candidates.isEmpty ? null : candidates.first;
    });
  }

  @override
  Future<Result<List<ExchangeRateModel>, AppError>> getRatesForDateRange(
    String fromCurrency,
    String toCurrency,
    DateTime start,
    DateTime end,
  ) {
    return _guard.run('getRatesForDateRange', () async {
      return (await _readAll())
          .where((r) =>
              r.fromCurrency == fromCurrency &&
              r.toCurrency == toCurrency &&
              r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              r.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  Future<Result<void, AppError>> deleteOldRates(DateTime before) {
    return _guard.run('deleteOldRates', () async {
      final oldRates = (await _readAll()).where((r) => r.date.isBefore(before)).toList();
      for (final rate in oldRates) {
        await _storage.deleteRecord(table: _tableName, id: rate.id);
      }

      _logger.info('Deleted ${oldRates.length} old exchange rates');
    });
  }

  Future<List<ExchangeRateModel>> _readAll() async {
    final records = await _storage.getAllRecords(table: _tableName);
    return _parser.parseAll(records).where((r) => r.deletedAt == null).toList();
  }
}
