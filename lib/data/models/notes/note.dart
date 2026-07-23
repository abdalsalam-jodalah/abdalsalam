import '../../models/base_model.dart';

class Note extends BaseModel {
  final String userId;
  final String title;
  final String content;
  final List<String> tags;
  final String? categoryId;
  final bool pinned;
  final bool archived;
  final List<String> attachments;
  final String? color;
  final int order;

  const Note({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    required this.content,
    required this.tags,
    required this.categoryId,
    required this.pinned,
    required this.archived,
    required this.attachments,
    required this.color,
    this.order = 0,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        categoryId: json['categoryId'] as String?,
        pinned: json['pinned'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        attachments: (json['attachments'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        color: json['color'] as String?,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  Note copyWith({
    DateTime? updatedAt,
    String? title,
    String? content,
    int? order,
  }) =>
      Note(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags,
        categoryId: categoryId,
        pinned: pinned,
        archived: archived,
        attachments: attachments,
        color: color,
        order: order ?? this.order,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'title': title,
        'content': content,
        'tags': tags,
        'categoryId': categoryId,
        'pinned': pinned,
        'archived': archived,
        'attachments': attachments,
        'color': color,
        'order': order,
      };
}
