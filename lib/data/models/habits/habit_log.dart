import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class HabitLog extends BaseModel {
  final String userId;
  final String habitId;
  final DateTime completedAt;
  final double? value;
  final String? notes;
  final String? mood;
  final String? skipReason;
  final String? situation;
  final String? cause;
  final String? trigger;
  final String? location;
  final String? thoughtsBefore;
  final String? thoughtsAfter;
  final int? intensity;
  final String? recoveryAction;

  const HabitLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.habitId,
    required this.completedAt,
    this.value,
    this.notes,
    this.mood,
    this.skipReason,
    this.situation,
    this.cause,
    this.trigger,
    this.location,
    this.thoughtsBefore,
    this.thoughtsAfter,
    this.intensity,
    this.recoveryAction,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'HabitLog');
    final createdAt = reader.requireDate('createdAt');
    return HabitLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      habitId: reader.requireString('habitId'),
      completedAt: reader.requireDate('completedAt'),
      value: reader.optionalDouble('value'),
      notes: reader.optionalString('notes'),
      mood: reader.optionalString('mood'),
      skipReason: reader.optionalString('skipReason'),
      situation: reader.optionalString('situation'),
      cause: reader.optionalString('cause'),
      trigger: reader.optionalString('trigger'),
      location: reader.optionalString('location'),
      thoughtsBefore: reader.optionalString('thoughtsBefore'),
      thoughtsAfter: reader.optionalString('thoughtsAfter'),
      intensity: reader.optionalInt('intensity'),
      recoveryAction: reader.optionalString('recoveryAction'),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'habitId': habitId,
        'completedAt': completedAt.toIso8601String(),
        'value': value,
        'notes': notes,
        'mood': mood,
        'skipReason': skipReason,
        'situation': situation,
        'cause': cause,
        'trigger': trigger,
        'location': location,
        'thoughtsBefore': thoughtsBefore,
        'thoughtsAfter': thoughtsAfter,
        'intensity': intensity,
        'recoveryAction': recoveryAction,
      };
}
