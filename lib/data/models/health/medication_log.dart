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

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        medicationId: json['medicationId'] as String,
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        scheduledTime: json['scheduledTime'] as String,
        takenAt: json['takenAt'] == null ? null : DateTime.parse(json['takenAt'] as String),
        skipped: json['skipped'] as bool? ?? false,
        skipReason: json['skipReason'] as String?,
        sideEffects: json['sideEffects'] as String?,
        notes: json['notes'] as String?,
      );

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
        takenAt: takenAt ?? this.takenAt,
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
