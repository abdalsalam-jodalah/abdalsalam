import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:abdalsalam/shared/services/notification_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';
import 'package:abdalsalam/shared/services/settings_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ThrowingReminderService extends ReminderService {
  ThrowingReminderService(LoggerService logger)
      : super(
          storage: StorageGateway.instance,
          logger: logger,
          notifications: NotificationService(plugin: FlutterLocalNotificationsPlugin(), logger: logger),
          settings: SettingsService(StorageGateway.instance),
        );

  @override
  Future<void> schedule(ReminderPayload payload) async {
    throw StateError('fake reminder failure');
  }

  @override
  void handleNotificationTap(ReminderPayload payload) {
    throw StateError('fake reminder tap failure');
  }
}
