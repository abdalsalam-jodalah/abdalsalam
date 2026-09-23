import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'WeeklyScheduleEntry');
    final createdAt = reader.requireDate('createdAt');
    return WeeklyScheduleEntry(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      dayOfWeek: reader.requireInt('dayOfWeek'),
      exerciseId: reader.requireString('exerciseId'),
      order: reader.readInt('order'),
      enabled: reader.readBool('enabled', fallback: true),
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
