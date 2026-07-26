import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  sleep,
  food,
}

class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  final LoggerService logger;

  NotificationService({required this.plugin, required this.logger});

  static const markTakenActionId = 'mark_taken';
  static const _medicationCategoryId = 'medication_actions';

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
    NotificationChannelType.sleep: AndroidNotificationChannel(
      'sleep_channel',
      'Sleep',
      description: 'Sleep logging reminders',
      importance: Importance.defaultImportance,
    ),
    NotificationChannelType.food: AndroidNotificationChannel(
      'food_channel',
      'Food',
      description: 'Meal logging reminders',
      importance: Importance.defaultImportance,
    ),
  };

  Future<void> initialize({
    void Function(String? payload, {String? actionId})? onNotificationTap,
  }) async {
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (error) {
      logger.warning('[NotificationService] timezone detection failed, using UTC: $error');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _medicationCategoryId,
          actions: [
            DarwinNotificationAction.plain(markTakenActionId, 'Mark as taken'),
          ],
        ),
      ],
    );
    final settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload, actionId: response.actionId);
      },
    );

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
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin =
        plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  NotificationDetails _detailsFor(NotificationChannelType channel, {bool withMarkTakenAction = false}) {
    final selectedChannel = channels[channel]!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        selectedChannel.id,
        selectedChannel.name,
        channelDescription: selectedChannel.description,
        importance: selectedChannel.importance,
        priority: Priority.high,
        actions: withMarkTakenAction
            ? const [AndroidNotificationAction(markTakenActionId, 'Mark as taken')]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: withMarkTakenAction ? _medicationCategoryId : null,
      ),
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    String? payload,
    bool withMarkTakenAction = false,
  }) async {
    await plugin.show(
      id,
      title,
      body,
      _detailsFor(channel, withMarkTakenAction: withMarkTakenAction),
      payload: payload,
    );
  }

  Future<void> zonedSchedule({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    required DateTime scheduledAt,
    String? payload,
    bool recurringDaily = false,
    bool withMarkTakenAction = false,
  }) async {
    await plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      _detailsFor(channel, withMarkTakenAction: withMarkTakenAction),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: recurringDaily ? DateTimeComponents.time : null,
      payload: payload,
    );
    logger.info(
      '[NotificationService] scheduled id=$id at ${scheduledAt.toIso8601String()}'
      '${recurringDaily ? ' (recurring daily)' : ''}',
    );
  }

  Future<void> cancel(int id) async {
    await plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    return plugin.pendingNotificationRequests();
  }
}
