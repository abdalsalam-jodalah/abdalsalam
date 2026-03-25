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
    return Reminder(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      reminderTime: DateTime.parse(json['reminderTime'] as String),
      type: ReminderType.values.byName(json['type'] as String),
      sent: json['sent'] as bool? ?? false,
      snoozedUntil: json['snoozedUntil'] == null
          ? null
          : DateTime.parse(json['snoozedUntil'] as String),
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
