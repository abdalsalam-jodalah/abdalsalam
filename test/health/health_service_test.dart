import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/health/services/health_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReminderService reminders;
  late HealthService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    reminders = FakeReminderService();
    service = HealthService(
      FakeHealthRepository(),
      LoggerService.forModule('HealthServiceTest'),
      reminders: reminders,
    );
  });

  group('HealthService.scheduleMedicationReminders', () {
    test('should schedule one reminder per valid time', () async {
      final result = await service.scheduleMedicationReminders(
        buildMedication(reminderTimes: ['08:00', '20:30']),
      );

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled.map((payload) => payload.scheduledAt.hour), [8, 20]);
    });

    test('should skip malformed stored times instead of throwing', () async {
      final result = await service.scheduleMedicationReminders(
        buildMedication(reminderTimes: ['8h', '25:00', '12:61', '', '07:15']),
      );

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled.single.metadata?['time'], '07:15');
    });

    test('should return Failure when the reminder service throws', () async {
      reminders.shouldThrowOnSchedule = true;

      final result = await service.scheduleMedicationReminders(buildMedication());

      expect(result.error, isA<ServiceError>());
    });
  });

  group('HealthService.refreshReminders', () {
    test('should cancel then reschedule an active medication', () async {
      final result = await service.refreshReminders(buildMedication());

      expect(result.isSuccess, isTrue);
      expect(reminders.cancelledTargetIds, ['med-1']);
      expect(reminders.scheduled, hasLength(1));
    });

    test('should only cancel an inactive medication', () async {
      final result = await service.refreshReminders(buildMedication(isActive: false));

      expect(result.isSuccess, isTrue);
      expect(reminders.scheduled, isEmpty);
    });

    test('should return Failure instead of Success when scheduling fails', () async {
      reminders.shouldThrowOnSchedule = true;

      final result = await service.refreshReminders(buildMedication());

      expect(result.isFailure, isTrue);
    });

    test('should return Failure when the refill reminder fails', () async {
      reminders.shouldThrowOnSchedule = true;

      final result = await service.refreshReminders(
        buildMedication(reminderTimes: ['bad'], refillDate: DateTime(2030, 1, 10)),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
