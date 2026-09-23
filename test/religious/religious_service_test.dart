import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/repositories/religious/prayer_repository.dart';
import 'package:abdalsalam/features/religious/services/religious_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LoggerService logger;

  setUpAll(() async {
    await LoggerService.initialize();
    logger = LoggerService.forModule('ReligiousServiceTest');
  });

  ReligiousService buildService(FakeReminderService reminders) {
    return ReligiousService(
      PrayerRepositoryImpl(StorageGateway.instance, logger),
      logger,
      reminders: reminders,
    );
  }

  group('ReligiousService.schedulePrayerReminder', () {
    test('should schedule the reminder ten minutes before the prayer', () async {
      final reminders = FakeReminderService();
      final service = buildService(reminders);
      final prayerTime = DateTime(2026, 9, 23, 12, 15);

      final result = await service.schedulePrayerReminder(
        prayerName: 'Dhuhr',
        prayerTime: prayerTime,
        targetId: 'dhuhr-1',
      );

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled.single.scheduledAt, DateTime(2026, 9, 23, 12, 5));
    });

    test('should return failure instead of throwing when scheduling fails', () async {
      final service = buildService(FakeReminderService(shouldFail: true));

      final result = await service.schedulePrayerReminder(
        prayerName: 'Dhuhr',
        prayerTime: DateTime(2026, 9, 23, 12, 15),
        targetId: 'dhuhr-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServiceError>());
    });
  });
}
