import '../../models/base_model.dart';

class Medication extends BaseModel {
  final String userId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> reminderTimes; // Format: "HH:mm"
  final String? prescribedBy;
  final String? notes;
  final DateTime? refillDate;
  final int displayOrder; // For custom ordering in the list
  final bool isActive; // Quick toggle for pausing medication

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
    this.endDate,
    required this.reminderTimes,
    this.prescribedBy,
    this.notes,
    this.refillDate,
    this.displayOrder = 0,
    this.isActive = true,
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
        displayOrder: json['displayOrder'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  Medication copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? userId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reminderTimes,
    String? prescribedBy,
    String? notes,
    DateTime? refillDate,
    int? displayOrder,
    bool? isActive,
  }) =>
      Medication(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        frequency: frequency ?? this.frequency,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        reminderTimes: reminderTimes ?? this.reminderTimes,
        prescribedBy: prescribedBy ?? this.prescribedBy,
        notes: notes ?? this.notes,
        refillDate: refillDate ?? this.refillDate,
        displayOrder: displayOrder ?? this.displayOrder,
        isActive: isActive ?? this.isActive,
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
        'displayOrder': displayOrder,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        dosage,
        frequency,
        startDate,
        endDate,
        reminderTimes,
        prescribedBy,
        notes,
        refillDate,
        displayOrder,
        isActive,
      ];
}
