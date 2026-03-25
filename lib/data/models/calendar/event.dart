import '../base_model.dart';

class Event extends BaseModel {
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
    return Event(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      allDay: json['allDay'] as bool? ?? false,
      location: json['location'] as String?,
      attendees: (json['attendees'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>(),
      reminderMinutes:
          (json['reminderMinutes'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item as int)
              .toList(growable: false),
      googleEventId: json['googleEventId'] as String?,
      color: json['color'] as String? ?? '#00897B',
      category: json['category'] as String? ?? 'general',
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
