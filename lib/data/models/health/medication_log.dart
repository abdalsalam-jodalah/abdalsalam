import '../../models/base_model.dart';

class MedicationLog extends BaseModel {
  final String userId;
  final String medicationId;
  final DateTime takenAt;
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
    required this.takenAt,
    required this.skipped,
    required this.skipReason,
    required this.sideEffects,
    required this.notes,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) => MedicationLog(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        medicationId: json['medicationId'] as String,
        takenAt: DateTime.parse(json['takenAt'] as String),
        skipped: json['skipped'] as bool,
        skipReason: json['skipReason'] as String?,
        sideEffects: json['sideEffects'] as String?,
        notes: json['notes'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'medicationId': medicationId,
        'takenAt': takenAt.toIso8601String(),
        'skipped': skipped,
        'skipReason': skipReason,
        'sideEffects': sideEffects,
        'notes': notes,
      };
}
