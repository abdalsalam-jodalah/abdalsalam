import 'package:adhan/adhan.dart';

import '../../../shared/infrastructure/logger_service.dart';
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
  final LoggerService logger;
  final PrayerTimesCacheService cache;

  const PrayerTimeService({required this.logger, required this.cache});

  Future<Map<String, String>> calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    String method = 'muslim_world_league',
  }) async {
    final cached = await cache.getForDate(date, method);
    if (cached != null) {
      return cached;
    }

    final calculationMethod = _calculationMethods[method] ?? CalculationMethod.muslim_world_league;
    final params = calculationMethod.getParameters();
    final coordinates = Coordinates(latitude, longitude);
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents(date.year, date.month, date.day),
      params,
    );

    final result = <String, String>{
      'fajr': prayerTimes.fajr.toIso8601String(),
      'dhuhr': prayerTimes.dhuhr.toIso8601String(),
      'asr': prayerTimes.asr.toIso8601String(),
      'maghrib': prayerTimes.maghrib.toIso8601String(),
      'isha': prayerTimes.isha.toIso8601String(),
    };

    await cache.cacheForDate(date: date, method: method, times: result);
    logger.info('[PrayerTimeService] calculated and cached prayer times for ${date.toIso8601String().split('T').first} ($method)');
    return result;
  }
}
