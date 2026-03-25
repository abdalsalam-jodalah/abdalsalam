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
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
        userId: json['userId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: json['dueDate'] == null ? null : DateTime.parse(json['dueDate'] as String),
        priority: TodoPriority.values.byName(json['priority'] as String),
        status: TodoStatus.values.byName(json['status'] as String),
        categoryId: json['categoryId'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        reminderAt: json['reminderAt'] == null ? null : DateTime.parse(json['reminderAt'] as String),
        parentTodoId: json['parentTodoId'] as String?,
        order: json['order'] as int? ?? 0,
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
      };
}
