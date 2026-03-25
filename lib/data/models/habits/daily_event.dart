import '../../models/base_model.dart';

class DailyEvent extends BaseModel {
  final String userId;
  final String eventType;
  final String title;
  final String description;
  final DateTime occurredAt;
  final int? durationMinutes;
  final List<String> tags;
  final String? mood;
  final List<String> relatedHabits;

  const DailyEvent({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.eventType,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.durationMinutes,
    required this.tags,
    required this.mood,
    required this.relatedHabits,
  });

  factory DailyEvent.fromJson(Map<String, dynamic> json) {
    return DailyEvent(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      durationMinutes: json['durationMinutes'] as int?,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      mood: json['mood'] as String?,
      relatedHabits: (json['relatedHabits'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'eventType': eventType,
        'title': title,
        'description': description,
        'occurredAt': occurredAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'tags': tags,
        'mood': mood,
        'relatedHabits': relatedHabits,
      };
}
