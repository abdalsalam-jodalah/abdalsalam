import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';

class PrayerTimesCacheService {
  static const _key = 'prayer_times_cache';

  final StorageGateway storage;
  final LoggerService logger;

  const PrayerTimesCacheService({required this.storage, required this.logger});

  String _cacheKey(DateTime date, String method) =>
      '${date.toIso8601String().split('T').first}|$method';

  Future<void> cacheForDate({
    required DateTime date,
    required String method,
    required Map<String, String> times,
  }) async {
    final existing = await storage.get<Map<String, dynamic>>(_key) ?? <String, dynamic>{};
    existing[_cacheKey(date, method)] = <String, dynamic>{
      'times': times,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    existing.removeWhere((key, _) {
      final parsed = DateTime.tryParse(key.split('|').first);
      return parsed != null && parsed.isBefore(cutoff);
    });

    await storage.save(key: _key, value: existing);
    logger.debug('[PrayerTimesCache] cached for ${date.toIso8601String().split('T').first} ($method)');
  }

  Future<Map<String, String>?> getForDate(DateTime date, String method) async {
    final existing = await storage.get<Map<String, dynamic>>(_key);
    if (existing == null) {
      return null;
    }

    final value = existing[_cacheKey(date, method)];
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
