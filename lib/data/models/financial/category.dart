import '../../models/base_model.dart';

enum CategoryType { income, expense }

class Category extends BaseModel {
  final String userId;
  final String name;
  final CategoryType type;
  final String icon;
  final String color;
  final String? parentCategoryId;

  const Category({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentCategoryId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: CategoryType.values.byName(json['type'] as String),
      icon: json['icon'] as String,
      color: json['color'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'userId': userId,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'parentCategoryId': parentCategoryId,
    };
  }
}
