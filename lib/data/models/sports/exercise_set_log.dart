import '../base_model.dart';

class ExerciseSetLog extends BaseModel {
  final String userId;
  final String exerciseLogId;
  final int setNumber;
  final int reps;
  final double? weightKg;

  const ExerciseSetLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.exerciseLogId,
    required this.setNumber,
    required this.reps,
    this.weightKg,
  });

  factory ExerciseSetLog.fromJson(Map<String, dynamic> json) {
    return ExerciseSetLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      exerciseLogId: json['exerciseLogId'] as String,
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
    );
  }

  ExerciseSetLog copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? setNumber,
    int? reps,
    double? weightKg,
  }) =>
      ExerciseSetLog(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        exerciseLogId: exerciseLogId,
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weightKg: weightKg ?? this.weightKg,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'exerciseLogId': exerciseLogId,
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
      };
}
