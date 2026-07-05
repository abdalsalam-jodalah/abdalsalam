import '../../models/base_model.dart';
import 'goal.dart';

class Achievement extends BaseModel {
  final String userId;
  final String? goalId;
  final String title;
  final String? description;
  final DateTime achievedAt;
  final GoalScope? scope;

  const Achievement({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    this.goalId,
    required this.title,
    this.description,
    required this.achievedAt,
    this.scope,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      goalId: json['goalId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      scope: json['scope'] == null ? null : GoalScope.values.byName(json['scope'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'goalId': goalId,
        'title': title,
        'description': description,
        'achievedAt': achievedAt.toIso8601String(),
        'scope': scope?.name,
      };
}
