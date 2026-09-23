import '../../../core/json/json_reader.dart';
import '../base_model.dart';

enum ReminderType { notification, email }

class Reminder extends BaseModel {
  final String userId;
  final String eventId;
  final DateTime reminderTime;
  final ReminderType type;
  final bool sent;
  final DateTime? snoozedUntil;

  const Reminder({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.eventId,
    required this.reminderTime,
    required this.type,
    required this.sent,
    required this.snoozedUntil,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Reminder');
    final createdAt = reader.requireDate('createdAt');
    return Reminder(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      eventId: reader.requireString('eventId'),
      reminderTime: reader.requireDate('reminderTime'),
      type: reader.readEnum('type', ReminderType.values, fallback: ReminderType.notification),
      sent: reader.readBool('sent'),
      snoozedUntil: reader.optionalDate('snoozedUntil'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'userId': userId,
      'eventId': eventId,
      'reminderTime': reminderTime.toIso8601String(),
      'type': type.name,
      'sent': sent,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }
}
