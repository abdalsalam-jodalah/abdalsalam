import '../../../core/json/json_reader.dart';
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

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'NoteCategory');
    final createdAt = reader.requireDate('createdAt');
    return NoteCategory(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      icon: reader.readString('icon'),
      color: reader.readString('color'),
      type: reader.readEnum('type', NoteCategoryType.values, fallback: NoteCategoryType.note),
      parentId: reader.optionalString('parentId'),
    );
  }

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
