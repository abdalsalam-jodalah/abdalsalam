import '../../../core/json/json_reader.dart';
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

  factory Note.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Note');
    final createdAt = reader.requireDate('createdAt');
    return Note(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      content: reader.readString('content'),
      tags: reader.readStringList('tags'),
      categoryId: reader.optionalString('categoryId'),
      pinned: reader.readBool('pinned'),
      archived: reader.readBool('archived'),
      attachments: reader.readStringList('attachments'),
      color: reader.optionalString('color'),
      order: reader.readInt('order'),
    );
  }

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
