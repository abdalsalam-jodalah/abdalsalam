import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../shared/services/error_handler.dart';

class PrayerTimesCacheService {
  static const _key = 'prayer_times_cache';
  static const _keySeparator = '|';
  static const _timesField = 'times';
  static const _cachedAtField = 'cachedAt';
  static const _retention = Duration(days: 30);

  final StorageGateway storage;
  final LoggerService logger;

  const PrayerTimesCacheService({required this.storage, required this.logger});

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  String _dateLabel(DateTime date) => date.toIso8601String().split('T').first;

  String _cacheKey(DateTime date, String method) => '${_dateLabel(date)}$_keySeparator$method';

  Future<Result<void, AppError>> cacheForDate({
    required DateTime date,
    required String method,
    required Map<String, DateTime> times,
  }) async {
    try {
      final existing = await _readCache();
      existing[_cacheKey(date, method)] = <String, dynamic>{
        _timesField: times.map((name, time) => MapEntry(name, time.toIso8601String())),
        _cachedAtField: DateTime.now().toIso8601String(),
      };

      final cutoff = DateTime.now().subtract(_retention);
      existing.removeWhere((key, _) {
        final parsed = DateTime.tryParse(key.split(_keySeparator).first);
        return parsed != null && parsed.isBefore(cutoff);
      });

      await storage.save(key: _key, value: existing);
      logger.debug('[PrayerTimesCache] cached for ${_dateLabel(date)} ($method)');
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(
        _errorHandler.mapException(error, context: 'PrayerTimesCache.cacheForDate', stackTrace: stackTrace),
      );
    }
  }

  Future<Result<Map<String, DateTime>?, AppError>> getForDate(DateTime date, String method) async {
    try {
      final existing = await _readCache();
      final entry = JsonReader(existing, source: _key).optionalMap(_cacheKey(date, method));
      if (entry == null) {
        return const Success(null);
      }

      final storedTimes = JsonReader(entry, source: _key).optionalMap(_timesField);
      if (storedTimes == null) {
        logger.warning('[PrayerTimesCache] ignoring malformed entry for ${_dateLabel(date)} ($method)');
        return const Success(null);
      }

      final timesReader = JsonReader(storedTimes, source: _key);
      final times = <String, DateTime>{};
      for (final name in storedTimes.keys) {
        final time = timesReader.optionalDate(name);
        if (time == null) {
          logger.warning('[PrayerTimesCache] ignoring unparseable "$name" for ${_dateLabel(date)} ($method)');
          return const Success(null);
        }
        times[name] = time;
      }
      return Success(times);
    } catch (error, stackTrace) {
      return Failure(
        _errorHandler.mapException(error, context: 'PrayerTimesCache.getForDate', stackTrace: stackTrace),
      );
    }
  }

  Future<Map<String, dynamic>> _readCache() async {
    final stored = await storage.get<Map<String, dynamic>>(_key);
    return <String, dynamic>{...?stored};
  }
}
