import 'package:flutter/material.dart';
import '../../../core/json/json_reader.dart';
import '../base_model.dart';
import 'financial_icon_palette.dart';

enum CategoryType { income, expense }

class CategoryModel extends BaseModel {
  final String userId;
  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;
  final String? parentCategoryId;

  const CategoryModel({
    required super.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentCategoryId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory CategoryModel.unknown() {
    final now = DateTime.now();
    return CategoryModel(
      id: '',
      userId: '',
      name: 'Unknown',
      type: CategoryType.expense,
      icon: Icons.help,
      color: Colors.grey,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'type': type.name,
        'iconKey': financialIconKeyFor(icon),
        'colorValue': color.toARGB32(),
        'parentCategoryId': parentCategoryId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'CategoryModel');
    final createdAt = reader.requireDate('createdAt');
    final iconKey = reader.optionalString('iconKey');
    return CategoryModel(
      id: reader.requireString('id'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      type: reader.requireEnum('type', CategoryType.values),
      icon: iconKey != null
          ? financialIconForKey(iconKey)
          : financialIconForLegacyCodePoint(
              reader.optionalInt('iconCodePoint'),
              reader.optionalString('iconFontFamily'),
            ),
      color: Color(reader.readInt('colorValue', fallback: financialDefaultColorValue)),
      parentCategoryId: reader.optionalString('parentCategoryId'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    CategoryType? type,
    IconData? icon,
    Color? color,
    String? parentCategoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        icon,
        color,
        parentCategoryId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
