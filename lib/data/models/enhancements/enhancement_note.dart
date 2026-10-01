// lib/data/models/enhancements/enhancement_note.dart: a personal note about something to improve in the app.
import '../../../core/json/json_reader.dart';
import '../base_model.dart';

enum EnhancementPriority { low, medium, high }

class EnhancementNote extends BaseModel {
  final String userId;
  final String title;
  final String? details;
  final EnhancementPriority priority;
  final bool isDone;
  final DateTime? completedAt;

  const EnhancementNote({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    this.details,
    this.priority = EnhancementPriority.medium,
    this.isDone = false,
    this.completedAt,
  });

  EnhancementNote copyWith({
    String? title,
    String? details,
    EnhancementPriority? priority,
    bool? isDone,
    DateTime? completedAt,
    bool clearDetails = false,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) =>
      EnhancementNote(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        details: clearDetails ? null : (details ?? this.details),
        priority: priority ?? this.priority,
        isDone: isDone ?? this.isDone,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      );

  factory EnhancementNote.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'EnhancementNote');
    final createdAt = reader.requireDate('createdAt');
    return EnhancementNote(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      details: reader.optionalString('details'),
      priority: reader.readEnum('priority', EnhancementPriority.values, fallback: EnhancementPriority.medium),
      isDone: reader.readBool('isDone'),
      completedAt: reader.optionalDate('completedAt'),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'title': title,
        'details': details,
        'priority': priority.name,
        'isDone': isDone,
        'completedAt': completedAt?.toIso8601String(),
      };
}
