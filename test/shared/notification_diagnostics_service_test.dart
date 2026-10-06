import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_diagnostics_service.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_reschedule_summary.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications extends NotificationService {
  bool isEnabled = true;
  bool canScheduleExact = true;
  bool isShowFailing = false;
  bool isScheduleFailing = false;
  bool isPendingEmpty = false;
  final List<int> scheduledIds = [];
  DateTime? scheduledAt;

  _FakeNotifications({required super.plugin, required super.logger});

  @override
  Future<Result<bool, AppError>> areNotificationsEnabled() async => Success(isEnabled);

  @override
  Future<Result<bool, AppError>> canScheduleExactAlarms() async => Success(canScheduleExact);

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
    return isShowFailing ? Failure(ServiceError('show rejected', cause: 'Missing type parameter')) : const Success(null);
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
    if (isScheduleFailing) {
      return Failure(ServiceError('schedule rejected'));
    }
    scheduledIds.add(id);
    this.scheduledAt = scheduledAt;
    return const Success(null);
  }

  @override
  Future<Result<List<PendingNotificationRequest>, AppError>> pendingNotifications() async {
    if (isPendingEmpty) return const Success(<PendingNotificationRequest>[]);
    return Success([for (final id in scheduledIds) PendingNotificationRequest(id, 'Test', 'Body', null)]);
  }
}

class _FakeReminders extends ReminderService {
  ReminderRescheduleSummary summary = const ReminderRescheduleSummary(
    rescheduledCount: 3,
    skippedCount: 1,
    failedCount: 0,
  );

  _FakeReminders({required super.storage, required super.logger, required super.notifications, required super.settings});

  @override
  Future<Result<ReminderRescheduleSummary, AppError>> rescheduleAll() async => Success(summary);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNotifications notifications;
  late _FakeReminders reminders;
  late NotificationDiagnosticsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    final logger = LoggerService.forModule('NotificationDiagnosticsTest');
    notifications = _FakeNotifications(plugin: FlutterLocalNotificationsPlugin(), logger: logger);
    reminders = _FakeReminders(
      storage: StorageGateway.instance,
      logger: logger,
      notifications: notifications,
      settings: SettingsService(StorageGateway.instance),
    );
    service = NotificationDiagnosticsService(notifications: notifications, reminders: reminders);
  });

  test('should pass every check when everything works', () async {
    final report = await service.run(now: DateTime(2026, 10, 6, 12));

    expect(report.isHealthy, isTrue);
    expect(report.checks, hasLength(6));
    expect(notifications.scheduledAt, DateTime(2026, 10, 6, 12, 1));
  });

  test('should fail the permission check when notifications are blocked by the system', () async {
    notifications.isEnabled = false;

    final report = await service.run();

    expect(report.isHealthy, isFalse);
    expect(report.checks.first.isPassed, isFalse);
    expect(report.checks.first.detail, contains('Notifications'));
  });

  test('should fail the exact alarm check when exact alarms are not allowed', () async {
    notifications.canScheduleExact = false;

    final report = await service.run();

    expect(report.checks[1].isPassed, isFalse);
  });

  test('should surface the underlying cause when showing a notification fails', () async {
    notifications.isShowFailing = true;

    final report = await service.run();

    final immediate = report.checks[2];
    expect(immediate.isPassed, isFalse);
    expect(immediate.detail, contains('Missing type parameter'));
  });

  test('should fail the pending check when the scheduled notification is not stored', () async {
    notifications.isPendingEmpty = true;

    final report = await service.run();

    expect(report.checks[4].isPassed, isFalse);
  });

  test('should fail the scheduled check and the pending check when scheduling is rejected', () async {
    notifications.isScheduleFailing = true;

    final report = await service.run();

    expect(report.checks[3].isPassed, isFalse);
    expect(report.checks[4].isPassed, isFalse);
  });

  test('should fail the reminders check when some reminders could not be rescheduled', () async {
    reminders.summary = const ReminderRescheduleSummary(rescheduledCount: 2, skippedCount: 0, failedCount: 2);

    final report = await service.run();

    expect(report.checks[5].isPassed, isFalse);
    expect(report.checks[5].detail, contains('2 failed'));
  });
}
