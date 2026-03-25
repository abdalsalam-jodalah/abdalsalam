import '../../models/base_model.dart';

class Medication extends BaseModel {
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> reminderTimes;
  final String? prescribedBy;
  final String? notes;
  final DateTime? refillDate;

  const Medication({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.reminderTimes,
    required this.prescribedBy,
    required this.notes,
    required this.refillDate,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        frequency: json['frequency'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        reminderTimes: (json['reminderTimes'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        prescribedBy: json['prescribedBy'] as String?,
        notes: json['notes'] as String?,
        refillDate: json['refillDate'] == null ? null : DateTime.parse(json['refillDate'] as String),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'reminderTimes': reminderTimes,
        'prescribedBy': prescribedBy,
        'notes': notes,
        'refillDate': refillDate?.toIso8601String(),
      };
}
