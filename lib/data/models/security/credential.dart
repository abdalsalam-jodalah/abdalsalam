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
    return Credential(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      title: json['title'] as String,
      username: json['username'] as String,
      encryptedPassword: json['encryptedPassword'] as String,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      categoryId: json['categoryId'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      favorite: json['favorite'] as bool? ?? false,
      lastModified: DateTime.parse(json['lastModified'] as String),
      strength: (json['strength'] as num?)?.toInt() ?? 0,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
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
