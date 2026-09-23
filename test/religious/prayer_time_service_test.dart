import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/features/religious/services/prayer_time_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const latitude = 32.2211;
  const longitude = 35.2544;
  final date = DateTime(2026, 9, 23);
  late LoggerService logger;

  setUpAll(() async {
    await LoggerService.initialize();
    logger = LoggerService.forModule('PrayerTimeServiceTest');
  });

  Map<String, DateTime> fixedTimes() {
    return <String, DateTime>{
      for (final prayer in PrayerName.values) prayer.name: DateTime(2026, 9, 23, prayer.index + 4),
    };
  }

  group('PrayerTimeService', () {
    test('should calculate five ordered prayer times and cache them', () async {
      final cache = FakePrayerTimesCacheService();
      final service = PrayerTimeService(logger: logger, cache: cache);

      final result = await service.calculatePrayerTimes(date: date, latitude: latitude, longitude: longitude);

      expect(result.isSuccess, isTrue);
      final times = result.data!;
      expect(times.keys, PrayerName.values.map((prayer) => prayer.name));
      final ordered = PrayerName.values.map((prayer) => times[prayer.name]!).toList();
      for (var i = 1; i < ordered.length; i++) {
        expect(ordered[i].isAfter(ordered[i - 1]), isTrue);
      }
      expect(cache.written.single, times);
    });

    test('should return cached times without recalculating', () async {
      final cached = fixedTimes();
      final cache = FakePrayerTimesCacheService(readResult: Success(cached));
      final service = PrayerTimeService(logger: logger, cache: cache);

      final result = await service.calculatePrayerTimes(date: date, latitude: latitude, longitude: longitude);

      expect(result.data, cached);
      expect(cache.written, isEmpty);
    });

    test('should recalculate when the cached entry is incomplete', () async {
      final cache = FakePrayerTimesCacheService(
        readResult: Success(<String, DateTime>{PrayerName.fajr.name: DateTime(2026, 9, 23, 4)}),
      );
      final service = PrayerTimeService(logger: logger, cache: cache);

      final result = await service.calculatePrayerTimes(date: date, latitude: latitude, longitude: longitude);

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(PrayerName.values.length));
      expect(cache.written, hasLength(1));
    });

    test('should still calculate when the cache cannot be read or written', () async {
      final cache = FakePrayerTimesCacheService(
        readResult: Failure(CorruptDataError('cache unreadable')),
        writeResult: Failure(StorageUnavailableError('prefs down')),
      );
      final service = PrayerTimeService(logger: logger, cache: cache);

      final result = await service.calculatePrayerTimes(date: date, latitude: latitude, longitude: longitude);

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(PrayerName.values.length));
    });

    test('should fall back to the default method for an unknown method', () async {
      final service = PrayerTimeService(logger: logger, cache: FakePrayerTimesCacheService());

      final unknown = await service.calculatePrayerTimes(
        date: date,
        latitude: latitude,
        longitude: longitude,
        method: 'not-a-method',
      );
      final fallback = await service.calculatePrayerTimes(date: date, latitude: latitude, longitude: longitude);

      expect(unknown.data, fallback.data);
    });
  });
}
