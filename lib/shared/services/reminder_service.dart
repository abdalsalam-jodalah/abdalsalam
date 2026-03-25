import 'dart:async';

import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';

enum ReminderModule { religious, financial, habits, sports, health, notes }

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

  final StorageGateway storage;
  final LoggerService logger;
  final StreamController<ReminderPayload> _tapController =
      StreamController<ReminderPayload>.broadcast();

  ReminderService({required this.storage, required this.logger});

  Stream<ReminderPayload> get tapStream => _tapController.stream;

  Future<void> schedule(ReminderPayload payload) async {
    final existing = await getAllScheduled();
    final updated = <Map<String, dynamic>>[
      ...existing.map((item) => item.toJson()),
      payload.toJson(),
    ];
    await storage.save(key: _storageKey, value: updated);
    logger.info('[ReminderService] scheduled ${payload.module.name}:${payload.targetId} at ${payload.scheduledAt.toIso8601String()}');
  }

  Future<List<ReminderPayload>> getAllScheduled() async {
    final raw = await storage.get<List<dynamic>>(_storageKey) ?? const <dynamic>[];
    return raw
        .whereType<Map>()
        .map((entry) => entry.map((k, v) => MapEntry(k.toString(), v)))
        .map(ReminderPayload.fromJson)
        .toList(growable: false);
  }

  void handleNotificationTap(ReminderPayload payload) {
    logger.info('[ReminderService] tapped ${payload.module.name}:${payload.targetId}');
    _tapController.add(payload);
  }

  Future<void> dispose() async {
    await _tapController.close();
  }
}
