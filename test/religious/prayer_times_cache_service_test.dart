import 'package:abdalsalam/features/religious/services/prayer_times_cache_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const cacheKey = 'prayer_times_cache';
  const method = 'muslim_world_league';
  final storage = StorageGateway.instance;
  final date = DateTime.now();
  final dateLabel = date.toIso8601String().split('T').first;
  late PrayerTimesCacheService cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_prayer_times_cache_service_test.db');
    await storage.save(key: cacheKey, value: <String, dynamic>{});
    cache = PrayerTimesCacheService(storage: storage, logger: LoggerService.forModule('PrayerTimesCacheTest'));
  });

  group('PrayerTimesCacheService', () {
    test('should return the cached times for the same date and method', () async {
      final times = <String, DateTime>{
        'fajr': DateTime(date.year, date.month, date.day, 4, 30),
        'isha': DateTime(date.year, date.month, date.day, 20, 10),
      };
      await cache.cacheForDate(date: date, method: method, times: times);

      final result = await cache.getForDate(date, method);

      expect(result.isSuccess, isTrue);
      expect(result.data, times);
    });

    test('should return no cached times when nothing is stored', () async {
      final result = await cache.getForDate(date, method);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('should ignore a stored entry with an unparseable time instead of throwing', () async {
      await storage.save(key: cacheKey, value: <String, dynamic>{
        '$dateLabel|$method': <String, dynamic>{
          'times': <String, dynamic>{'fajr': 'not-a-date'},
        },
      });

      final result = await cache.getForDate(date, method);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('should ignore a stored entry whose times are not a map', () async {
      await storage.save(key: cacheKey, value: <String, dynamic>{
        '$dateLabel|$method': <String, dynamic>{'times': 'broken'},
      });

      final result = await cache.getForDate(date, method);

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}
