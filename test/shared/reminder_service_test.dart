import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotificationService extends NotificationService {
  final List<int> scheduledIds = [];
  final List<DateTime> scheduledTimes = [];
  final List<int> shownNowIds = [];
  final List<int> cancelledIds = [];
  final Set<int> failingIds = {};

  _FakeNotificationService({required super.plugin, required super.logger});

  final List<bool> quietFlags = [];

  Result<void, AppError> _outcomeFor(int id) {
    if (failingIds.contains(id)) {
      return Failure(ServiceError('plugin rejected $id'));
    }
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    required DateTime scheduledAt,
    String? payload,
    bool recurringDaily = false,
    bool withMarkTakenAction = false,
    bool quiet = false,
  }) async {
    if (failingIds.contains(id)) {
      return _outcomeFor(id);
    }
    scheduledIds.add(id);
    scheduledTimes.add(scheduledAt);
    quietFlags.add(quiet);
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    String? payload,
    bool withMarkTakenAction = false,
    bool quiet = false,
  }) async {
    if (failingIds.contains(id)) {
      return _outcomeFor(id);
    }
    shownNowIds.add(id);
    quietFlags.add(quiet);
    return const Success(null);
  }

  @override
  Future<Result<void, AppError>> cancel(int id) async {
    if (failingIds.contains(id)) {
      return _outcomeFor(id);
    }
    cancelledIds.add(id);
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderService', () {
    late ReminderService service;
    late _FakeNotificationService notifications;

    ReminderPayload buildPayload({
      String targetId = 'target-1',
      ReminderModule module = ReminderModule.health,
      DateTime? scheduledAt,
    }) {
      return ReminderPayload(
        module: module,
        targetId: targetId,
        title: 'Title',
        body: 'Body',
        scheduledAt: scheduledAt ?? DateTime(2030, 1, 1, 8, 0),
      );
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_reminder_service_test.db');
      await StorageGateway.instance.delete('scheduled_reminders');
      await StorageGateway.instance.delete('reminder_settings');
      final logger = LoggerService.forModule('ReminderServiceTest');
      notifications = _FakeNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
        logger: logger,
      );
      service = ReminderService(
        storage: StorageGateway.instance,
        logger: logger,
        notifications: notifications,
        settings: SettingsService(StorageGateway.instance),
      );
    });

    test('should produce deterministic non-negative notification ids', () {
      final first = buildPayload();
      final second = buildPayload();
      final different = buildPayload(targetId: 'target-2');

      expect(first.notificationId, second.notificationId);
      expect(first.notificationId, isNot(different.notificationId));
      expect(first.notificationId, greaterThanOrEqualTo(0));
      expect(different.notificationId, greaterThanOrEqualTo(0));
    });

    test('should persist and schedule a future reminder', () async {
      final payload = buildPayload();

      await service.schedule(payload);

      final stored = await service.getAllScheduled();
      expect(stored.length, 1);
      expect(stored.first.targetId, payload.targetId);
      expect(notifications.scheduledIds, [payload.notificationId]);
      expect(notifications.shownNowIds, isEmpty);
    });

    test('should show a past-due reminder immediately instead of scheduling', () async {
      final payload = buildPayload(
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await service.schedule(payload);

      expect(notifications.scheduledIds, isEmpty);
      expect(notifications.shownNowIds, [payload.notificationId]);
    });

    test('should skip scheduling when module is disabled', () async {
      await service.setModuleEnabled(ReminderModule.health, false);

      await service.schedule(buildPayload());

      expect(await service.getAllScheduled(), isEmpty);
      expect(notifications.scheduledIds, isEmpty);
    });

    test('should cancel all entries for a target and keep others', () async {
      final kept = buildPayload(targetId: 'kept');
      final removed = buildPayload(targetId: 'removed');
      await service.schedule(kept);
      await service.schedule(removed);

      await service.cancel(ReminderModule.health, 'removed');

      final stored = await service.getAllScheduled();
      expect(stored.length, 1);
      expect(stored.first.targetId, 'kept');
      expect(notifications.cancelledIds, [removed.notificationId]);
    });

    test('should drop past reminders and reschedule future ones on rescheduleAll', () async {
      final past = buildPayload(
        targetId: 'past',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final future = buildPayload(targetId: 'future');
      await StorageGateway.instance.save(
        key: 'scheduled_reminders',
        value: [past.toJson(), future.toJson()],
      );

      final summary = (await service.rescheduleAll()).getOrThrow();

      expect(summary.rescheduledCount, 1);
      expect(summary.failedCount, 0);
      final stored = await service.getAllScheduled();
      expect(stored.length, 1);
      expect(stored.first.targetId, 'future');
      expect(notifications.scheduledIds, [future.notificationId]);
      expect(notifications.shownNowIds, isEmpty);
    });

    test('should deliver quietly by default (respectDoNotDisturb defaults true)', () async {
      await service.schedule(buildPayload());

      expect(notifications.quietFlags, [true]);
    });

    test('should deliver actively when respectDoNotDisturb is disabled', () async {
      final settingsService = SettingsService(StorageGateway.instance);
      await settingsService.updateSetting('respectDoNotDisturb', false);

      await service.schedule(buildPayload());

      expect(notifications.quietFlags, [false]);
    });

    test('should route notification payload json to tap stream', () async {
      final payload = buildPayload();
      final received = <ReminderPayload>[];
      final subscription = service.tapStream.listen(received.add);

      service.handleNotificationResponse(
        '{"module":"health","targetId":"target-1","title":"Title","body":"Body","scheduledAt":"2030-01-01T08:00:00.000"}',
      );
      await Future<void>.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received.first.targetId, payload.targetId);
      expect(received.first.notificationId, payload.notificationId);
      await subscription.cancel();
    });
    test('should keep rescheduling other reminders when one delivery fails', () async {
      final broken = buildPayload(targetId: 'broken');
      final first = buildPayload(targetId: 'first');
      final second = buildPayload(targetId: 'second');
      notifications.failingIds.add(broken.notificationId);
      await StorageGateway.instance.save(
        key: 'scheduled_reminders',
        value: [first.toJson(), broken.toJson(), second.toJson()],
      );

      final result = await service.rescheduleAll();

      final summary = result.getOrThrow();
      expect(summary.rescheduledCount, 2);
      expect(summary.failedCount, 1);
      expect(summary.hasFailures, isTrue);
      expect(notifications.scheduledIds, [first.notificationId, second.notificationId]);
    });

    test('should count reminders of disabled modules as skipped on rescheduleAll', () async {
      final payload = buildPayload();
      await StorageGateway.instance.save(key: 'scheduled_reminders', value: [payload.toJson()]);
      await service.setModuleEnabled(ReminderModule.health, false);

      final summary = (await service.rescheduleAll()).getOrThrow();

      expect(summary.skippedCount, 1);
      expect(summary.rescheduledCount, 0);
      expect(notifications.scheduledIds, isEmpty);
    });

    test('should treat a corrupt scheduled list as empty and report it', () async {
      StorageGateway.instance.integrityReporter.clearReports();
      await StorageGateway.instance.save(key: 'scheduled_reminders', value: {'not': 'a list'});

      final stored = await service.getAllScheduled();

      expect(stored, isEmpty);
      expect(
        StorageGateway.instance.integrityReporter.reports.map((report) => report.recordId),
        contains('scheduled_reminders'),
      );
    });

    test('should skip and report unreadable reminder entries while keeping valid ones', () async {
      StorageGateway.instance.integrityReporter.clearReports();
      final valid = buildPayload(targetId: 'valid');
      await StorageGateway.instance.save(
        key: 'scheduled_reminders',
        value: [
          valid.toJson(),
          {'module': 'unknown-module', 'targetId': 'x', 'scheduledAt': 'not a date'},
          'not an object',
        ],
      );

      final stored = await service.getAllScheduled();

      expect(stored.map((item) => item.targetId), ['valid']);
      expect(StorageGateway.instance.integrityReporter.corruptRecordCount, 2);
    });

    test('should fall back to enabled modules when reminder settings are corrupt', () async {
      StorageGateway.instance.integrityReporter.clearReports();
      await StorageGateway.instance.save(key: 'reminder_settings', value: ['not', 'a', 'map']);

      final settings = await service.getModuleSettings();

      expect(settings.values, everyElement(isTrue));
      expect(
        StorageGateway.instance.integrityReporter.reports.map((report) => report.recordId),
        contains('reminder_settings'),
      );
    });

    test('should throw the delivery error from schedule so callers can map it', () async {
      final payload = buildPayload();
      notifications.failingIds.add(payload.notificationId);

      expect(() => service.schedule(payload), throwsA(isA<ServiceError>()));
    });

    test('should ignore a malformed notification payload without emitting a tap', () async {
      final received = <ReminderPayload>[];
      final subscription = service.tapStream.listen(received.add);

      service.handleNotificationResponse('{"module":"health","targetId":"t","scheduledAt":"nope"}');
      service.handleNotificationResponse('not json');
      service.handleNotificationResponse('[1, 2]');
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await subscription.cancel();
    });
  });
}
