import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotificationService extends NotificationService {
  final List<int> scheduledIds = [];
  final List<DateTime> scheduledTimes = [];
  final List<int> shownNowIds = [];
  final List<int> cancelledIds = [];

  _FakeNotificationService({required super.plugin, required super.logger});

  @override
  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    scheduledIds.add(id);
    scheduledTimes.add(scheduledAt);
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    String? payload,
  }) async {
    shownNowIds.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
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
      await StorageGateway.instance.initialize(databaseName: 'test_abdalsalam.db');
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

      await service.rescheduleAll();

      final stored = await service.getAllScheduled();
      expect(stored.length, 1);
      expect(stored.first.targetId, 'future');
      expect(notifications.scheduledIds, [future.notificationId]);
      expect(notifications.shownNowIds, isEmpty);
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
  });
}
