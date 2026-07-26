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
    return ExerciseLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      exerciseId: json['exerciseId'] as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      scheduleEntryId: json['scheduleEntryId'] as String?,
      notes: json['notes'] as String?,
      steps: (json['steps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
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
