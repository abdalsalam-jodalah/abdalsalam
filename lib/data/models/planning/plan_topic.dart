import '../../models/base_model.dart';

class PlanTopic extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final String? parentTopicId;

  const PlanTopic({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    this.description,
    this.parentTopicId,
  });

  factory PlanTopic.fromJson(Map<String, dynamic> json) {
    return PlanTopic(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      parentTopicId: json['parentTopicId'] as String?,
    );
  }

  PlanTopic copyWith({
    DateTime? updatedAt,
    String? title,
    String? description,
  }) =>
      PlanTopic(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        parentTopicId: parentTopicId,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'title': title,
        'description': description,
        'parentTopicId': parentTopicId,
      };
}
