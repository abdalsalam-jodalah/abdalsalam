import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'ExerciseSetLog');
    final createdAt = reader.requireDate('createdAt');
    return ExerciseSetLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      exerciseLogId: reader.requireString('exerciseLogId'),
      setNumber: reader.readInt('setNumber'),
      reps: reader.requireInt('reps'),
      weightKg: reader.optionalDouble('weightKg'),
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
