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

  factory HealthMetric.fromJson(Map<String, dynamic> json) => HealthMetric(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        metricType: json['metricType'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        measuredAt: DateTime.parse(json['measuredAt'] as String),
        notes: json['notes'] as String?,
      );

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
