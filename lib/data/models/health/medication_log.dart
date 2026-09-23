import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class MedicationLog extends BaseModel {
  final String userId;
  final String medicationId;
  final DateTime scheduledFor; // When it was supposed to be taken
  final String scheduledTime; // Format: "HH:mm"
  final DateTime? takenAt; // When it was actually taken (null if not taken yet)
  final bool skipped;
  final String? skipReason;
  final String? sideEffects;
  final String? notes;

  const MedicationLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.medicationId,
    required this.scheduledFor,
    required this.scheduledTime,
    this.takenAt,
    this.skipped = false,
    this.skipReason,
    this.sideEffects,
    this.notes,
  });

  bool get isTaken => takenAt != null;
  bool get isPending => takenAt == null && !skipped;

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'MedicationLog');
    final createdAt = reader.requireDate('createdAt');
    return MedicationLog(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      medicationId: reader.requireString('medicationId'),
      scheduledFor: reader.requireDate('scheduledFor'),
      scheduledTime: reader.requireString('scheduledTime'),
      takenAt: reader.optionalDate('takenAt'),
      skipped: reader.readBool('skipped'),
      skipReason: reader.optionalString('skipReason'),
      sideEffects: reader.optionalString('sideEffects'),
      notes: reader.optionalString('notes'),
    );
  }

  MedicationLog copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    String? medicationId,
    DateTime? scheduledFor,
    String? scheduledTime,
    DateTime? takenAt,
    bool? takenAtIsNull = false,
    bool? skipped,
    String? skipReason,
    String? sideEffects,
    String? notes,
  }) =>
      MedicationLog(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId ?? this.userId,
        medicationId: medicationId ?? this.medicationId,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        takenAt: takenAtIsNull == true ? null : (takenAt ?? this.takenAt),
        skipped: skipped ?? this.skipped,
        skipReason: skipReason ?? this.skipReason,
        sideEffects: sideEffects ?? this.sideEffects,
        notes: notes ?? this.notes,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'medicationId': medicationId,
        'scheduledFor': scheduledFor.toIso8601String(),
        'scheduledTime': scheduledTime,
        'takenAt': takenAt?.toIso8601String(),
        'skipped': skipped,
        'skipReason': skipReason,
        'sideEffects': sideEffects,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        medicationId,
        scheduledFor,
        scheduledTime,
        takenAt,
        skipped,
        skipReason,
        sideEffects,
        notes,
      ];
}
