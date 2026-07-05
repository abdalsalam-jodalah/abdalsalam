import '../../models/base_model.dart';

enum GoalScope { life, yearly, quarterly, monthly, weekly, daily }

enum GoalStatus { notStarted, inProgress, achieved, abandoned }

class Goal extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final GoalScope scope;
  final GoalStatus status;
  final DateTime? targetDate;
  final String? parentGoalId;
  final double progress;
  final String? area;

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
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scope: GoalScope.values.byName(json['scope'] as String),
      status: GoalStatus.values.byName(json['status'] as String),
      targetDate: json['targetDate'] == null ? null : DateTime.parse(json['targetDate'] as String),
      parentGoalId: json['parentGoalId'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      area: json['area'] as String?,
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
    String? area,
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
        'area': area,
      };
}
