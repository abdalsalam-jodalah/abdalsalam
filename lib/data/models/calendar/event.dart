import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class Event extends BaseModel {
  static const String _defaultColor = '#00897B';
  static const String _defaultCategory = 'general';

  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? location;
  final List<String> attendees;
  final List<int> reminderMinutes;
  final String? googleEventId;
  final String color;
  final String category;

  const Event({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.allDay,
    required this.location,
    required this.attendees,
    required this.reminderMinutes,
    required this.googleEventId,
    required this.color,
    required this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Event');
    final createdAt = reader.requireDate('createdAt');
    final startTime = reader.requireDate('startTime');
    return Event(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      startTime: startTime,
      endTime: reader.readDate('endTime', fallback: startTime),
      allDay: reader.readBool('allDay'),
      location: reader.optionalString('location'),
      attendees: reader.readStringList('attendees'),
      reminderMinutes: reader.readIntList('reminderMinutes'),
      googleEventId: reader.optionalString('googleEventId'),
      color: reader.readString('color', fallback: _defaultColor),
      category: reader.readString('category', fallback: _defaultCategory),
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
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'allDay': allDay,
      'location': location,
      'attendees': attendees,
      'reminderMinutes': reminderMinutes,
      'googleEventId': googleEventId,
      'color': color,
      'category': category,
    };
  }
}
