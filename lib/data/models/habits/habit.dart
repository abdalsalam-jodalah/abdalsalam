import '../../../core/json/json_reader.dart';
import '../../models/base_model.dart';

enum HabitFrequency { daily, weekly, custom }

enum BadHabitCategory { sex, badMeal, badReaction, custom }

class Habit extends BaseModel {
  static const int _fallbackTargetCount = 1;
  static const String _fallbackIcon = 'star';
  static const String _fallbackColor = '#2196F3';
  static const String _customWeekdaysKey = 'customWeekdays';

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
  final bool isGoodHabit;
  final List<int>? customWeekdays;

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
    required this.isGoodHabit,
    this.customWeekdays,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'Habit');
    final createdAt = reader.requireDate('createdAt');
    return Habit(
      id: reader.requireString('id'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
      userId: reader.readString('userId'),
      name: reader.readString('name'),
      description: reader.readString('description'),
      frequency: reader.readEnum('frequency', HabitFrequency.values, fallback: HabitFrequency.daily),
      targetCount: reader.readInt('targetCount', fallback: _fallbackTargetCount),
      reminderTime: reader.optionalString('reminderTime'),
      icon: reader.readString('icon', fallback: _fallbackIcon),
      color: reader.readString('color', fallback: _fallbackColor),
      category: reader.readString('category'),
      badHabitCategory: reader.optionalEnum('badHabitCategory', BadHabitCategory.values),
      customBadHabitCategoryName: reader.optionalString('customBadHabitCategoryName'),
      isGoodHabit: reader.readBool('isGoodHabit', fallback: true),
      customWeekdays: json[_customWeekdaysKey] is List ? reader.readIntList(_customWeekdaysKey) : null,
    );
  }

  Habit copyWith({
    DateTime? updatedAt,
    String? name,
    String? description,
    HabitFrequency? frequency,
    int? targetCount,
    String? reminderTime,
    bool clearReminderTime = false,
    String? icon,
    String? color,
    String? category,
    BadHabitCategory? badHabitCategory,
    bool clearBadHabitCategory = false,
    String? customBadHabitCategoryName,
    bool clearCustomBadHabitCategoryName = false,
    bool? isGoodHabit,
    List<int>? customWeekdays,
    bool clearCustomWeekdays = false,
  }) =>
      Habit(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt,
        userId: userId,
        name: name ?? this.name,
        description: description ?? this.description,
        frequency: frequency ?? this.frequency,
        targetCount: targetCount ?? this.targetCount,
        reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
        icon: icon ?? this.icon,
        color: color ?? this.color,
        category: category ?? this.category,
        badHabitCategory: clearBadHabitCategory ? null : (badHabitCategory ?? this.badHabitCategory),
        customBadHabitCategoryName: clearCustomBadHabitCategoryName
            ? null
            : (customBadHabitCategoryName ?? this.customBadHabitCategoryName),
        isGoodHabit: isGoodHabit ?? this.isGoodHabit,
        customWeekdays: clearCustomWeekdays ? null : (customWeekdays ?? this.customWeekdays),
      );

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
        'isGoodHabit': isGoodHabit,
        'customWeekdays': customWeekdays,
      };
}
