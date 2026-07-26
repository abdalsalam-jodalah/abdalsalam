import '../base_model.dart';

class ExerciseCategory extends BaseModel {
  final String userId;
  final String name;
  final String? colorHex;
  final int order;

  const ExerciseCategory({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    this.colorHex,
    this.order = 0,
  });

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  ExerciseCategory copyWith({
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? name,
    String? colorHex,
    int? order,
  }) =>
      ExerciseCategory(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        userId: userId,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        order: order ?? this.order,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'colorHex': colorHex,
        'order': order,
      };
}
