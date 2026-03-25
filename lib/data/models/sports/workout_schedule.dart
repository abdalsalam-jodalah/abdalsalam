import '../../models/base_model.dart';

class WorkoutSchedule extends BaseModel {
  final String userId;
  final String workoutType;
  final DateTime scheduledFor;
  final bool completed;

  const WorkoutSchedule({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.workoutType,
    required this.scheduledFor,
    required this.completed,
  });

  factory WorkoutSchedule.fromJson(Map<String, dynamic> json) => WorkoutSchedule(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        workoutType: json['workoutType'] as String,
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        completed: json['completed'] as bool,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'workoutType': workoutType,
        'scheduledFor': scheduledFor.toIso8601String(),
        'completed': completed,
      };
}
