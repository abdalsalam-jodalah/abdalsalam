import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class TaskCategory extends BaseModel {
  static const String defaultColor = '#6B7280';

  final String userId;
  final String name;
  final String color;

  const TaskCategory({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    this.color = defaultColor,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'TaskCategory');
    final createdAt = reader.requireDate('createdAt');
    return TaskCategory(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      color: reader.readString('color', fallback: defaultColor),
    );
  }

  TaskCategory copyWith({DateTime? updatedAt, String? name, String? color}) => TaskCategory(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        name: name ?? this.name,
        color: color ?? this.color,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'color': color,
      };
}
