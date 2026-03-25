import '../../models/base_model.dart';

class Exercise extends BaseModel {
  final String userId;
  final String workoutId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight;
  final double? distance;
  final int? durationSeconds;
  final String muscleGroup;
  final String? instructions;
  final String? notes;

  const Exercise({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.workoutId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.distance,
    required this.durationSeconds,
    required this.muscleGroup,
    required this.instructions,
    required this.notes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        workoutId: json['workoutId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as int,
        weight: (json['weight'] as num?)?.toDouble(),
        distance: (json['distance'] as num?)?.toDouble(),
        durationSeconds: json['durationSeconds'] as int?,
        muscleGroup: json['muscleGroup'] as String,
        instructions: json['instructions'] as String?,
        notes: json['notes'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'workoutId': workoutId,
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'distance': distance,
        'durationSeconds': durationSeconds,
        'muscleGroup': muscleGroup,
        'instructions': instructions,
        'notes': notes,
      };
}
