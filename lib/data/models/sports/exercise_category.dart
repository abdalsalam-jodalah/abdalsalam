import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'ExerciseCategory');
    final createdAt = reader.requireDate('createdAt');
    return ExerciseCategory(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      colorHex: reader.optionalString('colorHex'),
      order: reader.readInt('order'),
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
