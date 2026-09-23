import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'Exercise');
    final createdAt = reader.requireDate('createdAt');
    return Exercise(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      categoryId: reader.requireString('categoryId'),
      trackingType: reader.requireEnum('trackingType', ExerciseTrackingType.values),
      difficulty: reader.readEnum(
        'difficulty',
        ExerciseDifficulty.values,
        fallback: ExerciseDifficulty.intermediate,
      ),
      equipment: reader.optionalString('equipment'),
      defaultSets: reader.optionalInt('defaultSets'),
      defaultReps: reader.optionalInt('defaultReps'),
      defaultWeightKg: reader.optionalDouble('defaultWeightKg'),
      instructions: reader.optionalString('instructions'),
      notes: reader.optionalString('notes'),
      order: reader.readInt('order'),
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
