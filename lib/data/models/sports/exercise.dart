import '../base_model.dart';

enum ExerciseTrackingType { reps, cardio }

enum ExerciseDifficulty { beginner, intermediate, advanced }

class Exercise extends BaseModel {
  final String userId;
  final String name;
  final String categoryId;
  final ExerciseTrackingType trackingType;
  final ExerciseDifficulty difficulty;
  final String? equipment;
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeightKg;
  final String? instructions;
  final String? notes;
  final int order;

  const Exercise({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.categoryId,
    required this.trackingType,
    this.difficulty = ExerciseDifficulty.intermediate,
    this.equipment,
    this.defaultSets,
    this.defaultReps,
    this.defaultWeightKg,
    this.instructions,
    this.notes,
    this.order = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      trackingType: ExerciseTrackingType.values.byName(json['trackingType'] as String),
      difficulty: json['difficulty'] == null
          ? ExerciseDifficulty.intermediate
          : ExerciseDifficulty.values.byName(json['difficulty'] as String),
      equipment: json['equipment'] as String?,
      defaultSets: (json['defaultSets'] as num?)?.toInt(),
      defaultReps: (json['defaultReps'] as num?)?.toInt(),
      defaultWeightKg: (json['defaultWeightKg'] as num?)?.toDouble(),
      instructions: json['instructions'] as String?,
      notes: json['notes'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Exercise copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? categoryId,
    ExerciseTrackingType? trackingType,
    ExerciseDifficulty? difficulty,
    String? equipment,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeightKg,
    String? instructions,
    String? notes,
    int? order,
  }) =>
      Exercise(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        name: name ?? this.name,
        categoryId: categoryId ?? this.categoryId,
        trackingType: trackingType ?? this.trackingType,
        difficulty: difficulty ?? this.difficulty,
        equipment: equipment ?? this.equipment,
        defaultSets: defaultSets ?? this.defaultSets,
        defaultReps: defaultReps ?? this.defaultReps,
        defaultWeightKg: defaultWeightKg ?? this.defaultWeightKg,
        instructions: instructions ?? this.instructions,
        notes: notes ?? this.notes,
        order: order ?? this.order,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'categoryId': categoryId,
        'trackingType': trackingType.name,
        'difficulty': difficulty.name,
        'equipment': equipment,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultWeightKg': defaultWeightKg,
        'instructions': instructions,
        'notes': notes,
        'order': order,
      };
}
