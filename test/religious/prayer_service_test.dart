import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/data/repositories/religious/prayer_repository.dart';
import 'package:abdalsalam/features/religious/services/prayer_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrayerService', () {
    late PrayerService service;

    setUp(() async {
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_abdalsalam.db');
      final logger = LoggerService.forModule('PrayerServiceTest');
      final repository = PrayerRepository(StorageGateway.instance, logger);
      service = PrayerService(repository, logger);
    });

    test('logs prayer and reports statistics', () async {
      final result = await service.logPrayer(
        userId: 'u1',
        prayerName: PrayerName.fajr,
        onTime: true,
      );

      expect(result.isSuccess, isTrue);

      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 1);
      expect(stats.data?['onTimeCount'], 1);
    });
  });
}
