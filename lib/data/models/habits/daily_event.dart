import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'DailyEvent');
    final createdAt = reader.requireDate('createdAt');
    return DailyEvent(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      eventType: reader.readString('eventType'),
      title: reader.readString('title'),
      description: reader.readString('description'),
      occurredAt: reader.readDate('occurredAt', fallback: createdAt),
      durationMinutes: reader.optionalInt('durationMinutes'),
      tags: reader.readStringList('tags'),
      mood: reader.optionalString('mood'),
      relatedHabits: reader.readStringList('relatedHabits'),
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
