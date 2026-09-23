import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'PlanTopic');
    final createdAt = reader.requireDate('createdAt');
    return PlanTopic(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      parentTopicId: reader.optionalString('parentTopicId'),
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
