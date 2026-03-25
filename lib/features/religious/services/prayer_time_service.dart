import 'package:adhan/adhan.dart';

import '../../../shared/infrastructure/logger_service.dart';
import 'prayer_times_cache_service.dart';

class PrayerTimeService {
  final LoggerService logger;
  final PrayerTimesCacheService cache;

  const PrayerTimeService({required this.logger, required this.cache});

  Future<Map<String, String>> calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    final cached = await cache.getForDate(date);
    if (cached != null) {
      return cached;
    }

    final params = CalculationMethod.muslim_world_league.getParameters();
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

    await cache.cacheForDate(date: date, times: result);
    logger.info('[PrayerTimeService] calculated and cached prayer times for ${date.toIso8601String().split('T').first}');
    return result;
  }
}
