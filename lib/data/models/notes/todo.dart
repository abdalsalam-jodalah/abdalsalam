import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum TodoPriority { low, medium, high }
enum TodoStatus { pending, done, cancelled }

class Todo extends BaseModel {
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TodoPriority priority;
  final TodoStatus status;
  final String? categoryId;
  final List<String> tags;
  final DateTime? reminderAt;
  final String? parentTodoId;
  final int order;
  final String? habitId;

  const Todo({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.categoryId,
    required this.tags,
    required this.reminderAt,
    required this.parentTodoId,
    required this.order,
    this.habitId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Todo');
    final createdAt = reader.requireDate('createdAt');
    return Todo(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      title: reader.readString('title'),
      description: reader.optionalString('description'),
      dueDate: reader.optionalDate('dueDate'),
      priority: reader.readEnum('priority', TodoPriority.values, fallback: TodoPriority.medium),
      status: reader.readEnum('status', TodoStatus.values, fallback: TodoStatus.pending),
      categoryId: reader.optionalString('categoryId'),
      tags: reader.readStringList('tags'),
      reminderAt: reader.optionalDate('reminderAt'),
      parentTodoId: reader.optionalString('parentTodoId'),
      order: reader.readInt('order'),
      habitId: reader.optionalString('habitId'),
    );
  }

  Todo copyWith({
    DateTime? updatedAt,
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    TodoStatus? status,
    String? categoryId,
    List<String>? tags,
    DateTime? reminderAt,
    int? order,
    String? habitId,
    bool clearHabitId = false,
  }) =>
      Todo(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        categoryId: categoryId ?? this.categoryId,
        tags: tags ?? this.tags,
        reminderAt: reminderAt ?? this.reminderAt,
        parentTodoId: parentTodoId,
        order: order ?? this.order,
        habitId: clearHabitId ? null : (habitId ?? this.habitId),
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
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.name,
        'status': status.name,
        'categoryId': categoryId,
        'tags': tags,
        'reminderAt': reminderAt?.toIso8601String(),
        'parentTodoId': parentTodoId,
        'order': order,
        'habitId': habitId,
      };
}
