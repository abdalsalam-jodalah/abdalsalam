import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum GoalScope { life, yearly, quarterly, monthly, weekly, daily }

enum GoalStatus { notStarted, inProgress, achieved, abandoned }

enum LifeArea { mind, body, money, soul }

class Goal extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final GoalScope scope;
  final GoalStatus status;
  final DateTime? targetDate;
  final String? parentGoalId;
  final double progress;
  final LifeArea? area;
  final String? topicId;

  const Goal({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    this.description,
    required this.scope,
    required this.status,
    this.targetDate,
    this.parentGoalId,
    this.progress = 0.0,
    this.area,
    this.topicId,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Goal');
    final createdAt = reader.requireDate('createdAt');
    return Goal(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      scope: reader.readEnum('scope', GoalScope.values, fallback: GoalScope.life),
      status: reader.readEnum('status', GoalStatus.values, fallback: GoalStatus.notStarted),
      targetDate: reader.optionalDate('targetDate'),
      parentGoalId: reader.optionalString('parentGoalId'),
      progress: reader.readDouble('progress'),
      area: reader.optionalEnum('area', LifeArea.values),
      topicId: reader.optionalString('topicId'),
    );
  }

  Goal copyWith({
    DateTime? updatedAt,
    String? title,
    String? description,
    GoalScope? scope,
    GoalStatus? status,
    DateTime? targetDate,
    String? parentGoalId,
    double? progress,
    LifeArea? area,
    String? topicId,
  }) =>
      Goal(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        scope: scope ?? this.scope,
        status: status ?? this.status,
        targetDate: targetDate ?? this.targetDate,
        parentGoalId: parentGoalId ?? this.parentGoalId,
        progress: progress ?? this.progress,
        area: area ?? this.area,
        topicId: topicId ?? this.topicId,
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
        'scope': scope.name,
        'status': status.name,
        'targetDate': targetDate?.toIso8601String(),
        'parentGoalId': parentGoalId,
        'progress': progress,
        'area': area?.name,
        'topicId': topicId,
      };
}
