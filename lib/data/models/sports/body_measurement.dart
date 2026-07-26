import '../base_model.dart';

class BodyMeasurement extends BaseModel {
  final String userId;
  final DateTime date;
  final double weightKg;
  final double? heightCm;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? abdominalCm;
  final double? hipsCm;
  final double? thighCm;
  final double? armCm;
  final String? notes;

  const BodyMeasurement({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.date,
    required this.weightKg,
    this.heightCm,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.abdominalCm,
    this.hipsCm,
    this.thighCm,
    this.armCm,
    this.notes,
  });

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      abdominalCm: (json['abdominalCm'] as num?)?.toDouble(),
      hipsCm: (json['hipsCm'] as num?)?.toDouble(),
      thighCm: (json['thighCm'] as num?)?.toDouble(),
      armCm: (json['armCm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  BodyMeasurement copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? abdominalCm,
    double? hipsCm,
    double? thighCm,
    double? armCm,
    String? notes,
  }) =>
      BodyMeasurement(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        date: date ?? this.date,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
        chestCm: chestCm ?? this.chestCm,
        waistCm: waistCm ?? this.waistCm,
        abdominalCm: abdominalCm ?? this.abdominalCm,
        hipsCm: hipsCm ?? this.hipsCm,
        thighCm: thighCm ?? this.thighCm,
        armCm: armCm ?? this.armCm,
        notes: notes ?? this.notes,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bodyFatPercent': bodyFatPercent,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'abdominalCm': abdominalCm,
        'hipsCm': hipsCm,
        'thighCm': thighCm,
        'armCm': armCm,
        'notes': notes,
      };
}
