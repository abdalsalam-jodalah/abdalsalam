import 'notification_diagnostic_check.dart';

class NotificationDiagnosticsReport {
  final List<NotificationDiagnosticCheck> checks;

  const NotificationDiagnosticsReport(this.checks);

  bool get isHealthy => checks.every((check) => check.isPassed);

  int get failedCount => checks.where((check) => !check.isPassed).length;
}
