import '../../models/base_model.dart';

class HabitLog extends BaseModel {
  final String userId;
  final String habitId;
  final DateTime completedAt;
  final double? value;
  final String? notes;
  final String? mood;
  final String? skipReason;

  const HabitLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.habitId,
    required this.completedAt,
    this.value,
    this.notes,
    this.mood,
    this.skipReason,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      habitId: json['habitId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      value: (json['value'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      mood: json['mood'] as String?,
      skipReason: json['skipReason'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'habitId': habitId,
        'completedAt': completedAt.toIso8601String(),
        'value': value,
        'notes': notes,
        'mood': mood,
        'skipReason': skipReason,
      };
}
