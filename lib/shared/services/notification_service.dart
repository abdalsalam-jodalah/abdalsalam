import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import 'error_handler.dart';

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
  static const _serviceName = 'NotificationService';

  ErrorHandler get _errorHandler => ErrorHandler(logger);

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

  Future<Result<void, AppError>> initialize({
    void Function(String? payload, {String? actionId})? onNotificationTap,
  }) async {
    await _configureLocalTimezone();

    final pluginResult = await _guard('initialize.plugin', () => _initializePlugin(onNotificationTap));
    if (pluginResult.isFailure) {
      return pluginResult;
    }

    final channelsResult = await _guard('initialize.channels', _createAndroidChannels);
    if (channelsResult.isFailure) {
      return channelsResult;
    }

    final permissionsResult = await requestPermissions();
    if (permissionsResult.isFailure) {
      logger.warning('[$_serviceName] permissions request failed; notifications may be blocked by the OS');
    }

    logger.info('[$_serviceName] initialized');
    return const Success(null);
  }

  Future<void> _configureLocalTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: '$_serviceName.initialize.timezone', stackTrace: stackTrace);
      logger.warning('[$_serviceName] timezone detection failed, using UTC');
    }
  }

  Future<void> _initializePlugin(
    void Function(String? payload, {String? actionId})? onNotificationTap,
  ) async {
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
      macOS: iosInit,
    );
    await plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload, actionId: response.actionId);
      },
    );
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final channel in channels.values) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  Future<Result<void, AppError>> requestPermissions() {
    return _guard('requestPermissions', () async {
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

      final macOSPlugin =
          plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      await macOSPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    });
  }

  Future<Result<bool, AppError>> canScheduleExactAlarms() {
    return _guard('canScheduleExactAlarms', () async {
      final androidPlugin =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? true;
    });
  }

  /// Whether the OS currently allows this app to post notifications, per
  /// the platform's own authorization/enabled check. `true` on a platform
  /// with no such concept (or if the plugin can't answer), so callers only
  /// need to special-case an explicit `false`.
  Future<Result<bool, AppError>> areNotificationsEnabled() {
    return _guard('areNotificationsEnabled', () async {
      final androidPlugin =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? true;
      }

      final iosPlugin =
          plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        return (await iosPlugin.checkPermissions())?.isEnabled ?? true;
      }

      final macOSPlugin =
          plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      if (macOSPlugin != null) {
        return (await macOSPlugin.checkPermissions())?.isEnabled ?? true;
      }

      return true;
    });
  }

  NotificationDetails _detailsFor(
    NotificationChannelType channel, {
    bool withMarkTakenAction = false,
    bool quiet = false,
  }) {
    final selectedChannel = channels[channel]!;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        selectedChannel.id,
        selectedChannel.name,
        channelDescription: selectedChannel.description,
        importance: selectedChannel.importance,
        priority: quiet ? Priority.low : Priority.high,
        actions: withMarkTakenAction
            ? const [AndroidNotificationAction(markTakenActionId, 'Mark as taken')]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: withMarkTakenAction ? _medicationCategoryId : null,
        interruptionLevel:
            quiet ? InterruptionLevel.passive : InterruptionLevel.active,
      ),
    );
  }

  Future<Result<void, AppError>> showNow({
    required int id,
    required String title,
    required String body,
    required NotificationChannelType channel,
    String? payload,
    bool withMarkTakenAction = false,
    bool quiet = false,
  }) {
    return _guard('showNow', () async {
      await plugin.show(
        id,
        title,
        body,
        _detailsFor(channel, withMarkTakenAction: withMarkTakenAction, quiet: quiet),
        payload: payload,
      );
    });
  }

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
  }) {
    return _guard('zonedSchedule', () async {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledAt, tz.local),
        _detailsFor(channel, withMarkTakenAction: withMarkTakenAction, quiet: quiet),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: recurringDaily ? DateTimeComponents.time : null,
        payload: payload,
      );
      logger.info(
        '[$_serviceName] scheduled id=$id at ${scheduledAt.toIso8601String()}'
        '${recurringDaily ? ' (recurring daily)' : ''}',
      );
    });
  }

  Future<Result<void, AppError>> cancel(int id) {
    return _guard('cancel', () => plugin.cancel(id));
  }

  Future<Result<void, AppError>> cancelAll() {
    return _guard('cancelAll', plugin.cancelAll);
  }

  Future<Result<List<PendingNotificationRequest>, AppError>> pendingNotifications() {
    return _guard('pendingNotifications', plugin.pendingNotificationRequests);
  }

  Future<Result<T, AppError>> _guard<T>(String operation, Future<T> Function() body) {
    return Result.guardAsync<T, AppError>(
      body,
      onError: (error, stackTrace) => _errorHandler.mapException(
        error,
        context: '$_serviceName.$operation',
        stackTrace: stackTrace,
      ),
    );
  }
}
