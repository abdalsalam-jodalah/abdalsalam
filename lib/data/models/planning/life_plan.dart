import '../../models/base_model.dart';

class LifePlan extends BaseModel {
  final String userId;
  final String visionStatement;
  final String missionStatement;
  final List<String> values;
  final List<String> principles;

  const LifePlan({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.visionStatement,
    required this.missionStatement,
    required this.values,
    required this.principles,
  });

  factory LifePlan.fromJson(Map<String, dynamic> json) {
    return LifePlan(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      visionStatement: json['visionStatement'] as String,
      missionStatement: json['missionStatement'] as String,
      values: (json['values'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      principles: (json['principles'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
    );
  }

  LifePlan copyWith({
    DateTime? updatedAt,
    String? visionStatement,
    String? missionStatement,
    List<String>? values,
    List<String>? principles,
  }) =>
      LifePlan(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        visionStatement: visionStatement ?? this.visionStatement,
        missionStatement: missionStatement ?? this.missionStatement,
        values: values ?? this.values,
        principles: principles ?? this.principles,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'visionStatement': visionStatement,
        'missionStatement': missionStatement,
        'values': values,
        'principles': principles,
      };
}
