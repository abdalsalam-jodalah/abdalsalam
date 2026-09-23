import '../../../core/json/json_reader.dart';
import '../base_model.dart';

class Credential extends BaseModel {
  final String userId;
  final String title;
  final String username;
  final String encryptedPassword;
  final String? website;
  final String? notes;
  final String? categoryId;
  final List<String> tags;
  final bool favorite;
  final DateTime lastModified;
  final int strength;
  final DateTime? expiryDate;

  const Credential({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    required this.username,
    required this.encryptedPassword,
    required this.website,
    required this.notes,
    required this.categoryId,
    required this.tags,
    required this.favorite,
    required this.lastModified,
    required this.strength,
    required this.expiryDate,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Credential');
    final createdAt = reader.requireDate('createdAt');
    final updatedAt = reader.readDate('updatedAt', fallback: createdAt);
    return Credential(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      username: reader.readString('username'),
      encryptedPassword: reader.requireString('encryptedPassword'),
      website: reader.optionalString('website'),
      notes: reader.optionalString('notes'),
      categoryId: reader.optionalString('categoryId'),
      tags: reader.readStringList('tags'),
      favorite: reader.readBool('favorite'),
      lastModified: reader.readDate('lastModified', fallback: updatedAt),
      strength: reader.readInt('strength'),
      expiryDate: reader.optionalDate('expiryDate'),
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
      'title': title,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'website': website,
      'notes': notes,
      'categoryId': categoryId,
      'tags': tags,
      'favorite': favorite,
      'lastModified': lastModified.toIso8601String(),
      'strength': strength,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}
