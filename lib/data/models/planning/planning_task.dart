import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

class PlanningTask extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final int order;
  final DateTime? date;
  final String? goalId;
  final List<String> categoryIds;

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
    this.categoryIds = const <String>[],
  });

  factory PlanningTask.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'PlanningTask');
    final createdAt = reader.requireDate('createdAt');
    return PlanningTask(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      isCompleted: reader.readBool('isCompleted'),
      order: reader.readInt('order'),
      date: reader.optionalDate('date'),
      goalId: reader.optionalString('goalId'),
      categoryIds: _readCategoryIds(json, reader),
    );
  }

  static List<String> _readCategoryIds(Map<String, dynamic> json, JsonReader reader) {
    if (json.containsKey('categoryIds')) {
      return reader.readStringList('categoryIds');
    }
    final legacyCategoryId = reader.optionalString('categoryId');
    return legacyCategoryId == null ? const <String>[] : <String>[legacyCategoryId];
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
    List<String>? categoryIds,
    bool clearDate = false,
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
        date: clearDate ? null : (date ?? this.date),
        goalId: clearGoalId ? null : (goalId ?? this.goalId),
        categoryIds: categoryIds ?? this.categoryIds,
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
        'categoryIds': categoryIds,
      };
}
