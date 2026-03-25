import '../../models/base_model.dart';

enum NoteCategoryType { note, todo }

class NoteCategory extends BaseModel {
  final String userId;
  final String name;
  final String icon;
  final String color;
  final NoteCategoryType type;
  final String? parentId;

  const NoteCategory({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.parentId,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) => NoteCategory(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as String,
        type: NoteCategoryType.values.byName(json['type'] as String),
        parentId: json['parentId'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type.name,
        'parentId': parentId,
      };
}
