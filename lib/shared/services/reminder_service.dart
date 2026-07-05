import 'dart:async';
import 'dart:convert';

import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'notification_service.dart';

enum ReminderModule {
  religious,
  financial,
  habits,
  sports,
  health,
  notes,
  calendar,
  security,
}

class ReminderPayload {
  final ReminderModule module;
  final String targetId;
  final String title;
  final String body;
  final DateTime scheduledAt;

  const ReminderPayload({
    required this.module,
    required this.targetId,
    required this.title,
    required this.body,
    required this.scheduledAt,
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
      };

  factory ReminderPayload.fromJson(Map<String, dynamic> json) => ReminderPayload(
        module: ReminderModule.values.byName(json['module'] as String),
        targetId: json['targetId'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      );
}

class ReminderService {
  static const _storageKey = 'scheduled_reminders';
  static const _settingsKey = 'reminder_settings';
  static const _preferencesKey = 'reminder_preferences';

  final StorageGateway storage;
  final LoggerService logger;
  final NotificationService notifications;
  final StreamController<ReminderPayload> _tapController =
      StreamController<ReminderPayload>.broadcast();

  ReminderService({
    required this.storage,
    required this.logger,
    required this.notifications,
  });

  Stream<ReminderPayload> get tapStream => _tapController.stream;

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
    await _deliver(payload);
    logger.info('[ReminderService] scheduled ${payload.module.name}:${payload.targetId} at ${payload.scheduledAt.toIso8601String()}');
  }

  Future<void> _deliver(ReminderPayload payload) async {
    final channel = NotificationChannelType.values.byName(payload.module.name);
    final encodedPayload = jsonEncode(payload.toJson());
    if (payload.scheduledAt.isAfter(DateTime.now())) {
      await notifications.zonedSchedule(
        id: payload.notificationId,
        title: payload.title,
        body: payload.body,
        channel: channel,
        scheduledAt: payload.scheduledAt,
        payload: encodedPayload,
      );
    } else {
      await notifications.showNow(
        id: payload.notificationId,
        title: payload.title,
        body: payload.body,
        channel: channel,
        payload: encodedPayload,
      );
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
      await notifications.cancel(payload.notificationId);
    }

    final remaining = existing
        .where((item) => !(item.module == module && item.targetId == targetId))
        .map((item) => item.toJson())
        .toList(growable: false);
    await storage.save(key: _storageKey, value: remaining);
    logger.info('[ReminderService] cancelled ${module.name}:$targetId (${matching.length} entries)');
  }

  Future<void> rescheduleAll() async {
    final existing = await getAllScheduled();
    final now = DateTime.now();
    final upcoming = existing
        .where((item) => item.scheduledAt.isAfter(now))
        .toList(growable: false);

    await storage.save(
      key: _storageKey,
      value: upcoming.map((item) => item.toJson()).toList(growable: false),
    );

    final settings = await getModuleSettings();
    for (final payload in upcoming) {
      if ((settings[payload.module.name] ?? true) == false) {
        continue;
      }
      await _deliver(payload);
    }
    logger.info('[ReminderService] rescheduled ${upcoming.length} of ${existing.length} reminders');
  }

  void handleNotificationResponse(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
      handleNotificationTap(ReminderPayload.fromJson(decoded));
    } catch (error) {
      logger.warning('[ReminderService] failed to parse notification payload: $error');
    }
  }

  Future<List<ReminderPayload>> getAllScheduled() async {
    final raw = await storage.get<List<dynamic>>(_storageKey) ?? const <dynamic>[];
    return raw
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
        .map(ReminderPayload.fromJson)
        .toList(growable: false);
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
    final raw = await storage.get<Map<String, dynamic>>(_settingsKey) ?? <String, dynamic>{};
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

  Future<void> setNotificationSound(String sound) async {
    final preferences = await getPreferences();
    preferences['sound'] = sound;
    await storage.save(key: _preferencesKey, value: preferences);
  }

  Future<void> setNotificationPriority(String priority) async {
    final preferences = await getPreferences();
    preferences['priority'] = priority;
    await storage.save(key: _preferencesKey, value: preferences);
  }

  Future<void> setRespectDoNotDisturb(bool enabled) async {
    final preferences = await getPreferences();
    preferences['respectDoNotDisturb'] = enabled;
    await storage.save(key: _preferencesKey, value: preferences);
  }

  Future<Map<String, dynamic>> getPreferences() async {
    return await storage.get<Map<String, dynamic>>(_preferencesKey) ??
        <String, dynamic>{
          'sound': 'default',
          'priority': 'default',
          'respectDoNotDisturb': true,
        };
  }

  Future<bool> shouldDeliverNotification() async {
    final prefs = await getPreferences();
    return (prefs['respectDoNotDisturb'] as bool? ?? true);
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
    }
  }

  void handleNotificationTap(ReminderPayload payload) {
    logger.info('[ReminderService] tapped ${payload.module.name}:${payload.targetId}');
    _tapController.add(payload);
  }

  Future<void> dispose() async {
    await _tapController.close();
  }
}
