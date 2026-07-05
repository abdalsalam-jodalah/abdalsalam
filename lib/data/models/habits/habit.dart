import '../../models/base_model.dart';

enum HabitFrequency { daily, weekly, custom }

enum BadHabitCategory { sex, badMeal, badReaction, custom }

class Habit extends BaseModel {
  final String userId;
  final String name;
  final String description;
  final HabitFrequency frequency;
  final int targetCount;
  final String? reminderTime;
  final String icon;
  final String color;
  final String category;
  final BadHabitCategory? badHabitCategory;
  final String? customBadHabitCategoryName;

  const Habit({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    required this.userId,
    required this.name,
    required this.description,
    required this.frequency,
    required this.targetCount,
    required this.reminderTime,
    required this.icon,
    required this.color,
    required this.category,
    this.badHabitCategory,
    this.customBadHabitCategoryName,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String),
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      frequency: HabitFrequency.values.byName(json['frequency'] as String),
      targetCount: json['targetCount'] as int,
      reminderTime: json['reminderTime'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      category: json['category'] as String,
      badHabitCategory: json['badHabitCategory'] == null
          ? null
          : BadHabitCategory.values.byName(json['badHabitCategory'] as String),
      customBadHabitCategoryName: json['customBadHabitCategoryName'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'userId': userId,
        'name': name,
        'description': description,
        'frequency': frequency.name,
        'targetCount': targetCount,
        'reminderTime': reminderTime,
        'icon': icon,
        'color': color,
        'category': category,
        'badHabitCategory': badHabitCategory?.name,
        'customBadHabitCategoryName': customBadHabitCategoryName,
      };
}
