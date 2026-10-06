import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import 'notification_diagnostic_check.dart';
import 'notification_diagnostics_report.dart';
import 'notification_service.dart';
import 'reminder_service.dart';

class NotificationDiagnosticsService {
  static const int immediateTestId = 2147480001;
  static const int scheduledTestId = 2147480002;
  static const Duration scheduledDelay = Duration(minutes: 1);
  static const NotificationChannelType _testChannel = NotificationChannelType.health;
  static const String _testTitle = 'Test notification';

  final NotificationService notifications;
  final ReminderService reminders;

  const NotificationDiagnosticsService({required this.notifications, required this.reminders});

  Future<NotificationDiagnosticsReport> run({DateTime? now}) async {
    final startedAt = now ?? DateTime.now();
    return NotificationDiagnosticsReport([
      await _checkPermission(),
      await _checkExactAlarms(),
      await _checkImmediate(),
      await _checkScheduled(startedAt),
      await _checkPending(),
      await _checkReminders(),
    ]);
  }

  Future<NotificationDiagnosticCheck> _checkPermission() async {
    const title = 'Notifications allowed by the system';
    final result = await notifications.areNotificationsEnabled();
    if (result.isFailure) {
      return _failed(title, result.error!);
    }
    if (result.data == false) {
      return const NotificationDiagnosticCheck(
        title: title,
        isPassed: false,
        detail: 'Blocked. Open system settings → Apps → this app → Notifications and turn them on.',
      );
    }
    return const NotificationDiagnosticCheck(title: title, isPassed: true, detail: 'Allowed');
  }

  Future<NotificationDiagnosticCheck> _checkExactAlarms() async {
    const title = 'Exact alarms allowed';
    final result = await notifications.canScheduleExactAlarms();
    if (result.isFailure) {
      return _failed(title, result.error!);
    }
    if (result.data == false) {
      return const NotificationDiagnosticCheck(
        title: title,
        isPassed: false,
        detail: 'Not allowed. Reminders may arrive late. Open system settings → Apps → Alarms & reminders.',
      );
    }
    return const NotificationDiagnosticCheck(title: title, isPassed: true, detail: 'Allowed');
  }

  Future<NotificationDiagnosticCheck> _checkImmediate() async {
    const title = 'Show a notification now';
    final result = await notifications.showNow(
      id: immediateTestId,
      title: _testTitle,
      body: 'Immediate notification works.',
      channel: _testChannel,
    );
    return _fromResult(title, result, passedDetail: 'Sent. You should see it in the notification shade.');
  }

  Future<NotificationDiagnosticCheck> _checkScheduled(DateTime startedAt) async {
    const title = 'Schedule a notification';
    final result = await notifications.zonedSchedule(
      id: scheduledTestId,
      title: _testTitle,
      body: 'Scheduled notification works.',
      channel: _testChannel,
      scheduledAt: startedAt.add(scheduledDelay),
    );
    return _fromResult(title, result, passedDetail: 'Scheduled for ${scheduledDelay.inMinutes} minute from now.');
  }

  Future<NotificationDiagnosticCheck> _checkPending() async {
    const title = 'Scheduled notification is waiting';
    final result = await notifications.pendingNotifications();
    if (result.isFailure) {
      return _failed(title, result.error!);
    }
    final pending = result.data!;
    final hasTestNotification = pending.any((request) => request.id == scheduledTestId);
    return NotificationDiagnosticCheck(
      title: title,
      isPassed: hasTestNotification,
      detail: hasTestNotification
          ? '${pending.length} pending in total'
          : 'The scheduled test notification was not found among ${pending.length} pending.',
    );
  }

  Future<NotificationDiagnosticCheck> _checkReminders() async {
    const title = 'Saved reminders reschedule';
    final result = await reminders.rescheduleAll();
    if (result.isFailure) {
      return _failed(title, result.error!);
    }
    final summary = result.data!;
    return NotificationDiagnosticCheck(
      title: title,
      isPassed: !summary.hasFailures,
      detail:
          '${summary.rescheduledCount} rescheduled, ${summary.skippedCount} skipped, ${summary.failedCount} failed',
    );
  }

  NotificationDiagnosticCheck _fromResult(String title, Result<void, AppError> result, {required String passedDetail}) {
    return result.isFailure
        ? _failed(title, result.error!)
        : NotificationDiagnosticCheck(title: title, isPassed: true, detail: passedDetail);
  }

  NotificationDiagnosticCheck _failed(String title, AppError error) {
    final cause = error.cause;
    final detail = cause == null ? error.message : '${error.message} ($cause)';
    return NotificationDiagnosticCheck(title: title, isPassed: false, detail: detail);
  }
}
