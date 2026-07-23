import '../../models/base_model.dart';

class PlanningTask extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int order;
  final DateTime? date;
  final String? goalId;

  const PlanningTask({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.order = 0,
    this.date,
    this.goalId,
  });

  factory PlanningTask.fromJson(Map<String, dynamic> json) {
    return PlanningTask(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt() ?? 0,
      date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
      goalId: json['goalId'] as String?,
    );
  }

  PlanningTask copyWith({
    DateTime? updatedAt,
    String? title,
    String? description,
    bool? isCompleted,
    int? order,
    DateTime? date,
    String? goalId,
    bool clearGoalId = false,
  }) =>
      PlanningTask(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        order: order ?? this.order,
        date: date ?? this.date,
        goalId: clearGoalId ? null : (goalId ?? this.goalId),
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
        'isCompleted': isCompleted,
        'order': order,
        'date': date?.toIso8601String(),
        'goalId': goalId,
      };
}
