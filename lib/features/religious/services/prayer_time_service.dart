import 'package:adhan/adhan.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';
import 'prayer_times_cache_service.dart';

const _calculationMethods = <String, CalculationMethod>{
  'muslim_world_league': CalculationMethod.muslim_world_league,
  'umm_al_qura': CalculationMethod.umm_al_qura,
  'egyptian': CalculationMethod.egyptian,
  'karachi': CalculationMethod.karachi,
  'dubai': CalculationMethod.dubai,
  'kuwait': CalculationMethod.kuwait,
  'qatar': CalculationMethod.qatar,
  'singapore': CalculationMethod.singapore,
  'north_america': CalculationMethod.north_america,
  'moon_sighting_committee': CalculationMethod.moon_sighting_committee,
};

class PrayerTimeService {
  static const String defaultMethod = 'muslim_world_league';

  final LoggerService logger;
  final PrayerTimesCacheService cache;

  const PrayerTimeService({required this.logger, required this.cache});

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Future<Result<Map<String, DateTime>, AppError>> calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String method = defaultMethod,
  }) async {
    final cached = await cache.getForDate(date, method);
    if (cached.isFailure) {
      logger.warning('[PrayerTimeService] cache read failed, recalculating: ${cached.error}');
    }
    final cachedTimes = cached.data;
    if (cachedTimes != null && _hasAllPrayers(cachedTimes)) {
      return Success(cachedTimes);
    }

    final calculated = Result.guard<Map<String, DateTime>, AppError>(
      () => _calculate(date: date, latitude: latitude, longitude: longitude, method: method),
      onError: (error, stackTrace) => _errorHandler.mapException(
        error,
        context: 'PrayerTimeService.calculatePrayerTimes',
        stackTrace: stackTrace,
      ),
    );
    if (calculated.isFailure) {
      return calculated;
    }

    final times = calculated.data!;
    final cachedWrite = await cache.cacheForDate(date: date, method: method, times: times);
    if (cachedWrite.isFailure) {
      logger.warning('[PrayerTimeService] cache write failed: ${cachedWrite.error}');
    }
    logger.info('[PrayerTimeService] calculated prayer times for ${date.toIso8601String().split('T').first} ($method)');
    return Success(times);
  }

  Map<String, DateTime> _calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String method,
  }) {
    final calculationMethod = _calculationMethods[method];
    if (calculationMethod == null) {
      logger.warning('[PrayerTimeService] unknown method "$method", falling back to $defaultMethod');
    }
    final params = (calculationMethod ?? CalculationMethod.muslim_world_league).getParameters();
    final prayerTimes = PrayerTimes(
      Coordinates(latitude, longitude),
      DateComponents(date.year, date.month, date.day),
      params,
    );

    return <String, DateTime>{
      PrayerName.fajr.name: prayerTimes.fajr,
      PrayerName.dhuhr.name: prayerTimes.dhuhr,
      PrayerName.asr.name: prayerTimes.asr,
      PrayerName.maghrib.name: prayerTimes.maghrib,
      PrayerName.isha.name: prayerTimes.isha,
    };
  }

  bool _hasAllPrayers(Map<String, DateTime> times) {
    return PrayerName.obligatory.every((prayer) => times.containsKey(prayer.name));
  }
}
