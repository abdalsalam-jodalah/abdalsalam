import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../infrastructure/logger_service.dart';

enum NotificationChannelType {
  religious,
  financial,
  habits,
  sports,
  health,
  notes,
  calendar,
  security,
}

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final LoggerService logger;

  NotificationService({required this.plugin, required this.logger});

  static const Map<NotificationChannelType, AndroidNotificationChannel>
      channels = <NotificationChannelType, AndroidNotificationChannel>{
    NotificationChannelType.religious: AndroidNotificationChannel(
      'religious_channel',
      'Religious',
      description: 'Prayer and spiritual reminders',
      importance: Importance.high,
    ),
    NotificationChannelType.financial: AndroidNotificationChannel(
      'financial_channel',
      'Financial',
      description: 'Budgets and spending alerts',
      importance: Importance.defaultImportance,
    ),
    NotificationChannelType.habits: AndroidNotificationChannel(
      'habits_channel',
      'Habits',
      description: 'Habit completion reminders',
      importance: Importance.defaultImportance,
    ),
    NotificationChannelType.sports: AndroidNotificationChannel(
      'sports_channel',
      'Sports',
      description: 'Workout reminders',
      importance: Importance.defaultImportance,
    ),
    NotificationChannelType.health: AndroidNotificationChannel(
      'health_channel',
      'Health',
      description: 'Medication and refill reminders',
      importance: Importance.high,
    ),
    NotificationChannelType.notes: AndroidNotificationChannel(
      'notes_channel',
      'Notes',
      description: 'Todo reminders',
      importance: Importance.defaultImportance,
    ),
    NotificationChannelType.calendar: AndroidNotificationChannel(
      'calendar_channel',
      'Calendar',
      description: 'Event reminders',
      importance: Importance.high,
    ),
    NotificationChannelType.security: AndroidNotificationChannel(
      'security_channel',
      'Security',
      description: 'Vault and password expiry reminders',
      importance: Importance.high,
    ),
  };

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await plugin.initialize(settings);

    final androidPlugin =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in channels.values) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    await requestPermissions();
    logger.info('[NotificationService] initialized');
  }

  Future<void> requestPermissions() async {
    final androidPlugin =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
  }) async {
    final selectedChannel = channels[channel]!;
    await plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          selectedChannel.id,
          selectedChannel.name,
          channelDescription: selectedChannel.description,
          importance: selectedChannel.importance,
          priority: Priority.high,
        ),
      ),
    );
  }
}
