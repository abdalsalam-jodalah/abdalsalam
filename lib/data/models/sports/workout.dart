import '../../models/base_model.dart';

class Workout extends BaseModel {
  final String userId;
  final String type;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int caloriesBurned;
  final String intensity;
  final String? location;

  const Workout({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.intensity,
    required this.location,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        type: json['type'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        durationMinutes: json['durationMinutes'] as int,
        caloriesBurned: json['caloriesBurned'] as int,
        intensity: json['intensity'] as String,
        location: json['location'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'type': type,
        'name': name,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'caloriesBurned': caloriesBurned,
        'intensity': intensity,
        'location': location,
      };
}
