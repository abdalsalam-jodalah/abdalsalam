import 'dart:async';
import 'dart:convert';

import '../../core/errors/app_error.dart';
import '../../core/json/json_reader.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'error_handler.dart';
import 'notification_service.dart';
import 'reminder_reschedule_summary.dart';
import 'settings_service.dart';

enum ReminderModule {
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

class ReminderPayload {
  final ReminderModule module;
  final String targetId;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool recurringDaily;
  final Map<String, dynamic>? metadata;

  const ReminderPayload({
    required this.module,
    required this.targetId,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.recurringDaily = false,
    this.metadata,
  });

  int get notificationId =>
      '${module.name}:$targetId:${scheduledAt.millisecondsSinceEpoch}'
          .hashCode &
      0x7fffffff;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'module': module.name,
        'targetId': targetId,
        'title': title,
        'body': body,
        'scheduledAt': scheduledAt.toIso8601String(),
        'recurringDaily': recurringDaily,
        'metadata': metadata,
      };

  factory ReminderPayload.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'ReminderPayload');
    return ReminderPayload(
      module: reader.requireEnum('module', ReminderModule.values),
      targetId: reader.requireString('targetId'),
      title: reader.readString('title'),
      body: reader.readString('body'),
      scheduledAt: reader.requireDate('scheduledAt'),
      recurringDaily: reader.readBool('recurringDaily'),
      metadata: reader.optionalMap('metadata'),
    );
  }
}

class ReminderService {
  static const _storageKey = 'scheduled_reminders';
  static const _settingsKey = 'reminder_settings';
  static const _serviceName = 'ReminderService';
  static const _preferencesSource = 'preferences';

  final StorageGateway storage;
  final LoggerService logger;
  final NotificationService notifications;
  final SettingsService settings;
  final StreamController<ReminderPayload> _tapController =
      StreamController<ReminderPayload>.broadcast();
  final StreamController<ReminderPayload> _markTakenController =
      StreamController<ReminderPayload>.broadcast();

  ReminderService({
    required this.storage,
    required this.logger,
    required this.notifications,
    required this.settings,
  });

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  Stream<ReminderPayload> get tapStream => _tapController.stream;

  /// Fires when the user taps the "Mark as taken" notification action
  /// instead of the notification body itself.
  Stream<ReminderPayload> get markTakenStream => _markTakenController.stream;

  Future<void> schedule(ReminderPayload payload) async {
    final settings = await getModuleSettings();
    if ((settings[payload.module.name] ?? true) == false) {
      logger.info('[ReminderService] skipped disabled module ${payload.module.name}');
      return;
    }

    final existing = await getAllScheduled();
    final updated = <Map<String, dynamic>>[
      ...existing.map((item) => item.toJson()),
      payload.toJson(),
    ];
    await storage.save(key: _storageKey, value: updated);
    final delivery = await _deliver(payload);
    if (delivery.isFailure) {
      throw delivery.error!;
    }
    logger.info('[ReminderService] scheduled ${payload.module.name}:${payload.targetId} at ${payload.scheduledAt.toIso8601String()}');
  }

  Future<Result<void, AppError>> _deliver(ReminderPayload payload) async {
    try {
      final enabled = await notifications.areNotificationsEnabled();
      if (enabled.data == false) {
        logger.info(
          '[$_serviceName] skipped ${payload.module.name}:${payload.targetId}; notifications are disabled at the OS level',
        );
        return const Success(null);
      }

      final channel = NotificationChannelType.values.byName(payload.module.name);
      final encodedPayload = jsonEncode(payload.toJson());
      final withMarkTakenAction = payload.module == ReminderModule.health && payload.metadata?['time'] != null;
      final quiet = await shouldDeliverQuietly();
      if (payload.scheduledAt.isAfter(DateTime.now())) {
        return await notifications.zonedSchedule(
          id: payload.notificationId,
          title: payload.title,
          body: payload.body,
          channel: channel,
          scheduledAt: payload.scheduledAt,
          payload: encodedPayload,
          recurringDaily: payload.recurringDaily,
          withMarkTakenAction: withMarkTakenAction,
          quiet: quiet,
        );
      }
      return await notifications.showNow(
        id: payload.notificationId,
        title: payload.title,
        body: payload.body,
        channel: channel,
        payload: encodedPayload,
        withMarkTakenAction: withMarkTakenAction,
        quiet: quiet,
      );
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$_serviceName.deliver', stackTrace: stackTrace));
    }
  }

  Future<void> cancel(ReminderModule module, String targetId) async {
    final existing = await getAllScheduled();
    final matching = existing
        .where((item) => item.module == module && item.targetId == targetId)
        .toList(growable: false);
    if (matching.isEmpty) {
      return;
    }

    for (final payload in matching) {
      final cancellation = await notifications.cancel(payload.notificationId);
      if (cancellation.isFailure) {
        throw cancellation.error!;
      }
    }

    final remaining = existing
        .where((item) => !(item.module == module && item.targetId == targetId))
        .map((item) => item.toJson())
        .toList(growable: false);
    await storage.save(key: _storageKey, value: remaining);
    logger.info('[ReminderService] cancelled ${module.name}:$targetId (${matching.length} entries)');
  }

  Future<Result<ReminderRescheduleSummary, AppError>> rescheduleAll() async {
    try {
      final existing = await getAllScheduled();
      final now = DateTime.now();
      final upcoming = existing
          .where((item) => item.scheduledAt.isAfter(now))
          .toList(growable: false);

      await storage.save(
        key: _storageKey,
        value: upcoming.map((item) => item.toJson()).toList(growable: false),
      );

      final moduleSettings = await getModuleSettings();
      var rescheduledCount = 0;
      var skippedCount = 0;
      var failedCount = 0;
      for (final payload in upcoming) {
        if ((moduleSettings[payload.module.name] ?? true) == false) {
          skippedCount++;
          continue;
        }
        final delivery = await _deliver(payload);
        if (delivery.isSuccess) {
          rescheduledCount++;
        } else {
          failedCount++;
          logger.warning(
            '[$_serviceName] failed to reschedule ${payload.module.name}:${payload.targetId}: ${delivery.error}',
          );
        }
      }

      final summary = ReminderRescheduleSummary(
        rescheduledCount: rescheduledCount,
        skippedCount: skippedCount,
        failedCount: failedCount,
      );
      if (summary.hasFailures) {
        logger.warning('[$_serviceName] $failedCount of ${upcoming.length} reminders failed to reschedule');
      }
      logger.info('[$_serviceName] rescheduled $rescheduledCount of ${existing.length} reminders');
      return Success(summary);
    } catch (error, stackTrace) {
      return Failure(_errorHandler.mapException(error, context: '$_serviceName.rescheduleAll', stackTrace: stackTrace));
    }
  }

  void handleNotificationResponse(String? rawPayload, {String? actionId}) {
    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map<String, dynamic>) {
        logger.warning('[$_serviceName] ignored notification payload that is not a JSON object');
        return;
      }
      final payload = ReminderPayload.fromJson(decoded);
      if (actionId == NotificationService.markTakenActionId) {
        logger.info('[ReminderService] mark-taken action ${payload.module.name}:${payload.targetId}');
        _markTakenController.add(payload);
      } else {
        handleNotificationTap(payload);
      }
    } catch (error, stackTrace) {
      _errorHandler.mapException(error, context: '$_serviceName.handleNotificationResponse', stackTrace: stackTrace);
    }
  }

  Future<List<ReminderPayload>> getAllScheduled() async {
    final rawEntries = await _readStoredValue<List<dynamic>>(_storageKey) ?? const <dynamic>[];
    final payloads = <ReminderPayload>[];
    for (var index = 0; index < rawEntries.length; index++) {
      final entry = rawEntries[index];
      final recordId = '$_storageKey[$index]';
      if (entry is! Map) {
        _reportCorrupt(recordId, CorruptDataError('Scheduled reminder is not an object', source: _storageKey));
        continue;
      }
      try {
        payloads.add(ReminderPayload.fromJson(entry.map((key, value) => MapEntry(key.toString(), value))));
      } on CorruptDataError catch (error, stackTrace) {
        _reportCorrupt(recordId, error, stackTrace);
      }
    }
    return List<ReminderPayload>.unmodifiable(payloads);
  }

  Future<T?> _readStoredValue<T>(String key) async {
    try {
      return await storage.get<T>(key);
    } on CorruptDataError catch (error, stackTrace) {
      _reportCorrupt(key, error, stackTrace);
      return null;
    }
  }

  void _reportCorrupt(String recordId, Object reason, [StackTrace? stackTrace]) {
    storage.integrityReporter.reportCorruptRecord(
      table: _preferencesSource,
      recordId: recordId,
      reason: reason,
      stackTrace: stackTrace,
    );
  }

  Future<void> schedulePrayerReminder({
    required String prayerId,
    required String title,
    required DateTime prayerTime,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.religious,
        targetId: prayerId,
        title: title,
        body: 'Prayer is in 10 minutes',
        scheduledAt: prayerTime.subtract(const Duration(minutes: 10)),
      ),
    );
  }

  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String name,
    required DateTime time,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.health,
        targetId: medicationId,
        title: 'Medication reminder',
        body: '$name dose time',
        scheduledAt: time,
      ),
    );
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String name,
    required DateTime time,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.habits,
        targetId: habitId,
        title: 'Habit reminder',
        body: 'Time for $name',
        scheduledAt: time,
      ),
    );
  }

  Future<void> scheduleTodoReminder({
    required String todoId,
    required String title,
    required DateTime reminderAt,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.notes,
        targetId: todoId,
        title: 'Todo reminder',
        body: title,
        scheduledAt: reminderAt,
      ),
    );
  }

  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime startAt,
    required int minutesBefore,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.calendar,
        targetId: eventId,
        title: 'Event reminder',
        body: '$title starts in $minutesBefore minutes',
        scheduledAt: startAt.subtract(Duration(minutes: minutesBefore)),
      ),
    );
  }

  Future<void> scheduleBudgetAlert({
    required String budgetId,
    required String message,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.financial,
        targetId: budgetId,
        title: 'Budget alert',
        body: message,
        scheduledAt: DateTime.now(),
      ),
    );
  }

  Future<void> scheduleSleepReminder({required DateTime time}) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.sleep,
        targetId: 'sleep_log_reminder',
        title: 'Sleep reminder',
        body: 'Time to log your sleep',
        scheduledAt: time,
      ),
    );
  }

  Future<void> scheduleFoodReminder({
    required DateTime time,
    required String mealLabel,
  }) async {
    await schedule(
      ReminderPayload(
        module: ReminderModule.food,
        targetId: 'food_log_reminder_$mealLabel',
        title: 'Food reminder',
        body: 'Time to log your $mealLabel',
        scheduledAt: time,
      ),
    );
  }

  Future<void> scheduleSnooze(
    ReminderPayload payload, {
    Duration duration = const Duration(minutes: 10),
  }) async {
    await schedule(
      ReminderPayload(
        module: payload.module,
        targetId: payload.targetId,
        title: payload.title,
        body: '${payload.body} (snoozed)',
        scheduledAt: DateTime.now().add(duration),
      ),
    );
  }

  Future<void> setModuleEnabled(ReminderModule module, bool enabled) async {
    final settings = await getModuleSettings();
    settings[module.name] = enabled;
    await storage.save(key: _settingsKey, value: settings);
  }

  Future<Map<String, bool>> getModuleSettings() async {
    final raw = await _readStoredValue<Map<String, dynamic>>(_settingsKey) ?? const <String, dynamic>{};
    final defaults = <String, bool>{
      for (final module in ReminderModule.values) module.name: true,
    };

    for (final entry in raw.entries) {
      if (entry.value is bool) {
        defaults[entry.key] = entry.value as bool;
      }
    }

    return defaults;
  }

  Future<bool> shouldDeliverQuietly() async {
    final userSettings = await settings.getSettings();
    return (userSettings['respectDoNotDisturb'] as bool?) ?? true;
  }

  String? routeForPayload(ReminderPayload payload) {
    switch (payload.module) {
      case ReminderModule.religious:
        return '/religious';
      case ReminderModule.financial:
        return '/financial';
      case ReminderModule.habits:
        return '/habits';
      case ReminderModule.sports:
        return '/sports';
      case ReminderModule.health:
        return '/health';
      case ReminderModule.notes:
        return '/notes';
      case ReminderModule.calendar:
        return '/calendar';
      case ReminderModule.security:
        return '/security';
      case ReminderModule.sleep:
        return '/sleep';
      case ReminderModule.food:
        return '/food';
    }
  }

  void handleNotificationTap(ReminderPayload payload) {
    logger.info('[ReminderService] tapped ${payload.module.name}:${payload.targetId}');
    _tapController.add(payload);
  }

  Future<void> dispose() async {
    await _tapController.close();
    await _markTakenController.close();
  }
}
