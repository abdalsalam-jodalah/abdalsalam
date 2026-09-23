import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class ExerciseLog extends BaseModel {
  final String userId;
  final DateTime date;
  final String exerciseId;
  final int order;
  final String? scheduleEntryId;
  final String? notes;
  final int? steps;
  final int? durationSeconds;
  final double? distanceKm;

  const ExerciseLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.date,
    required this.exerciseId,
    this.order = 0,
    this.scheduleEntryId,
    this.notes,
    this.steps,
    this.durationSeconds,
    this.distanceKm,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'ExerciseLog');
    final createdAt = reader.requireDate('createdAt');
    return ExerciseLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      date: reader.requireDate('date'),
      exerciseId: reader.requireString('exerciseId'),
      order: reader.readInt('order'),
      scheduleEntryId: reader.optionalString('scheduleEntryId'),
      notes: reader.optionalString('notes'),
      steps: reader.optionalInt('steps'),
      durationSeconds: reader.optionalInt('durationSeconds'),
      distanceKm: reader.optionalDouble('distanceKm'),
    );
  }

  ExerciseLog copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? date,
    String? exerciseId,
    int? order,
    String? scheduleEntryId,
    String? notes,
    int? steps,
    int? durationSeconds,
    double? distanceKm,
  }) =>
      ExerciseLog(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        date: date ?? this.date,
        exerciseId: exerciseId ?? this.exerciseId,
        order: order ?? this.order,
        scheduleEntryId: scheduleEntryId ?? this.scheduleEntryId,
        notes: notes ?? this.notes,
        steps: steps ?? this.steps,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'date': date.toIso8601String(),
        'exerciseId': exerciseId,
        'order': order,
        'scheduleEntryId': scheduleEntryId,
        'notes': notes,
        'steps': steps,
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
      };
}
