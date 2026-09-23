import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'BodyMeasurement');
    final createdAt = reader.requireDate('createdAt');
    return BodyMeasurement(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      date: reader.requireDate('date'),
      weightKg: reader.requireDouble('weightKg'),
      heightCm: reader.optionalDouble('heightCm'),
      bodyFatPercent: reader.optionalDouble('bodyFatPercent'),
      chestCm: reader.optionalDouble('chestCm'),
      waistCm: reader.optionalDouble('waistCm'),
      abdominalCm: reader.optionalDouble('abdominalCm'),
      hipsCm: reader.optionalDouble('hipsCm'),
      thighCm: reader.optionalDouble('thighCm'),
      armCm: reader.optionalDouble('armCm'),
      notes: reader.optionalString('notes'),
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
