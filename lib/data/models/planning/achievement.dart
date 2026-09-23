import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'Achievement');
    final createdAt = reader.requireDate('createdAt');
    return Achievement(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      goalId: reader.optionalString('goalId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      achievedAt: reader.readDate('achievedAt', fallback: createdAt),
      scope: reader.optionalEnum('scope', GoalScope.values),
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
