import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../shared/services/notification_service.dart';
import '../../shared/services/reminder_service.dart';
import 'startup_report.dart';

class AppBootstrapResult {
  final logic.AppStateManager appStateManager;
  final NotificationService notificationService;
  final ReminderService reminderService;
  final List<String>? initialSidebarOrder;
  final StartupReport startupReport;

  const AppBootstrapResult({
    required this.appStateManager,
    required this.notificationService,
    required this.reminderService,
    required this.initialSidebarOrder,
    required this.startupReport,
  });
}
