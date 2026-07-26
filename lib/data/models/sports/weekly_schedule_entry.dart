import '../base_model.dart';

class WeeklyScheduleEntry extends BaseModel {
  final String userId;
  final int dayOfWeek;
  final String exerciseId;
  final int order;
  final bool enabled;

  const WeeklyScheduleEntry({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.dayOfWeek,
    required this.exerciseId,
    this.order = 0,
    this.enabled = true,
  });

  factory WeeklyScheduleEntry.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      exerciseId: json['exerciseId'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  WeeklyScheduleEntry copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? dayOfWeek,
    String? exerciseId,
    int? order,
    bool? enabled,
  }) =>
      WeeklyScheduleEntry(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        exerciseId: exerciseId ?? this.exerciseId,
        order: order ?? this.order,
        enabled: enabled ?? this.enabled,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'dayOfWeek': dayOfWeek,
        'exerciseId': exerciseId,
        'order': order,
        'enabled': enabled,
      };
}
