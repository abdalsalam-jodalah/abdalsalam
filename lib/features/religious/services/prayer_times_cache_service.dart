import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';

class PrayerTimesCacheService {
  static const _key = 'prayer_times_cache';

  final StorageGateway storage;
  final LoggerService logger;

  const PrayerTimesCacheService({required this.storage, required this.logger});

  Future<void> cacheForDate({
    required DateTime date,
    required Map<String, String> times,
  }) async {
    final existing = await storage.get<Map<String, dynamic>>(_key) ?? <String, dynamic>{};
    existing[date.toIso8601String().split('T').first] = <String, dynamic>{
      'times': times,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    existing.removeWhere((key, _) {
      final parsed = DateTime.tryParse(key);
      return parsed != null && parsed.isBefore(cutoff);
    });

    await storage.save(key: _key, value: existing);
    logger.debug('[PrayerTimesCache] cached for ${date.toIso8601String().split('T').first}');
  }

  Future<Map<String, String>?> getForDate(DateTime date) async {
    final existing = await storage.get<Map<String, dynamic>>(_key);
    if (existing == null) {
      return null;
    }

    final key = date.toIso8601String().split('T').first;
    final value = existing[key];
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final times = value['times'];
    if (times is! Map) {
      return null;
    }
    return times.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
