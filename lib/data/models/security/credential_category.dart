import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class CredentialCategory extends BaseModel {
  final String userId;
  final String name;
  final String color;
  final String icon;

  const CredentialCategory({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory CredentialCategory.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'CredentialCategory');
    final createdAt = reader.requireDate('createdAt');
    return CredentialCategory(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      color: reader.readString('color'),
      icon: reader.readString('icon'),
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
      'color': color,
      'icon': icon,
    };
  }
}
