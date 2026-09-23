import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class HealthMetric extends BaseModel {
  final String userId;
  final String metricType;
  final double value;
  final String unit;
  final DateTime measuredAt;
  final String? notes;

  const HealthMetric({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.measuredAt,
    required this.notes,
  });

  HealthMetric copyWith({
    String? userId,
    String? metricType,
    double? value,
    String? unit,
    DateTime? measuredAt,
    String? notes,
    DateTime? updatedAt,
  }) =>
      HealthMetric(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId ?? this.userId,
        metricType: metricType ?? this.metricType,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        measuredAt: measuredAt ?? this.measuredAt,
        notes: notes ?? this.notes,
      );

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'HealthMetric');
    final createdAt = reader.requireDate('createdAt');
    return HealthMetric(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      metricType: reader.requireString('metricType'),
      value: reader.requireDouble('value'),
      unit: reader.readString('unit'),
      measuredAt: reader.readDate('measuredAt', fallback: createdAt),
      notes: reader.optionalString('notes'),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'metricType': metricType,
        'value': value,
        'unit': unit,
        'measuredAt': measuredAt.toIso8601String(),
        'notes': notes,
      };
}
