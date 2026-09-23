import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/habits/daily_event.dart';
import 'package:abdalsalam/data/models/habits/habit.dart';
import 'package:abdalsalam/data/models/habits/habit_log.dart';
import 'package:flutter_test/flutter_test.dart';

const String createdAtIso = '2026-01-01T08:00:00.000';
final DateTime createdAt = DateTime(2026, 1, 1, 8);

Map<String, dynamic> baseJson() => <String, dynamic>{
      'id': 'record-1',
      'createdAt': createdAtIso,
      'userId': 'user1',
    };

void main() {
  group('Habit.fromJson', () {
    Habit buildHabit() => Habit(
          id: 'habit-1',
          createdAt: createdAt,
          updatedAt: DateTime(2026, 1, 2),
          deletedAt: DateTime(2026, 1, 3),
          userId: 'user1',
          name: 'Read',
          description: 'Read daily',
          frequency: HabitFrequency.custom,
          targetCount: 3,
          reminderTime: '08:00',
          icon: 'book',
          color: '#FF0000',
          category: 'Mind',
          badHabitCategory: BadHabitCategory.badMeal,
          customBadHabitCategoryName: 'Snacks',
          isGoodHabit: false,
          customWeekdays: const <int>[1, 3],
        );

    test('should keep every field when round tripping valid json', () {
      final habit = buildHabit();

      final parsed = Habit.fromJson(habit.toJson());

      expect(parsed.toJson(), habit.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = Habit.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.deletedAt, isNull);
      expect(parsed.name, '');
      expect(parsed.frequency, HabitFrequency.daily);
      expect(parsed.targetCount, 1);
      expect(parsed.icon, 'star');
      expect(parsed.color, '#2196F3');
      expect(parsed.isGoodHabit, isTrue);
      expect(parsed.badHabitCategory, isNull);
      expect(parsed.customWeekdays, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['targetCount'] = 3.0
        ..['isGoodHabit'] = 0
        ..['customWeekdays'] = <dynamic>[1, 'x', 2.0];

      final parsed = Habit.fromJson(json);

      expect(parsed.targetCount, 3);
      expect(parsed.isGoodHabit, isFalse);
      expect(parsed.customWeekdays, <int>[1, 2]);
    });

    test('should fall back when dates are invalid', () {
      final json = baseJson()
        ..['updatedAt'] = 'not-a-date'
        ..['deletedAt'] = 'not-a-date';

      final parsed = Habit.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should fall back when enum values are unknown', () {
      final json = baseJson()
        ..['frequency'] = 'hourly'
        ..['badHabitCategory'] = 'unknown';

      final parsed = Habit.fromJson(json);

      expect(parsed.frequency, HabitFrequency.daily);
      expect(parsed.badHabitCategory, isNull);
    });

    test('should throw CorruptDataError when a required field is missing', () {
      final json = baseJson()..remove('id');

      expect(() => Habit.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('HabitLog.fromJson', () {
    Map<String, dynamic> logJson() => baseJson()
      ..['habitId'] = 'habit-1'
      ..['completedAt'] = '2026-01-01T09:00:00.000';

    test('should keep every field when round tripping valid json', () {
      final log = HabitLog(
        id: 'log-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        habitId: 'habit-1',
        completedAt: DateTime(2026, 1, 1, 9),
        value: 2.5,
        notes: 'note',
        mood: 'Good',
        skipReason: 'tired',
        situation: 'home',
        cause: 'stress',
        trigger: 'phone',
        location: 'room',
        thoughtsBefore: 'before',
        thoughtsAfter: 'after',
        intensity: 4,
        recoveryAction: 'walk',
      );

      final parsed = HabitLog.fromJson(log.toJson());

      expect(parsed.toJson(), log.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = logJson();

      final parsed = HabitLog.fromJson(json);

      expect(parsed.updatedAt, createdAt);
      expect(parsed.value, isNull);
      expect(parsed.notes, isNull);
      expect(parsed.intensity, isNull);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = logJson()
        ..['value'] = '2.5'
        ..['intensity'] = 4.0;

      final parsed = HabitLog.fromJson(json);

      expect(parsed.value, 2.5);
      expect(parsed.intensity, 4);
    });

    test('should return null when an optional date is invalid', () {
      final json = logJson()..['deletedAt'] = 'not-a-date';

      final parsed = HabitLog.fromJson(json);

      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when habitId is missing', () {
      final json = logJson()..remove('habitId');

      expect(() => HabitLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when completedAt is invalid', () {
      final json = logJson()..['completedAt'] = 'not-a-date';

      expect(() => HabitLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('DailyEvent.fromJson', () {
    test('should keep every field when round tripping valid json', () {
      final event = DailyEvent(
        id: 'event-1',
        createdAt: createdAt,
        updatedAt: DateTime(2026, 1, 2),
        userId: 'user1',
        eventType: 'meeting',
        title: 'Standup',
        description: 'Daily sync',
        occurredAt: DateTime(2026, 1, 1, 10),
        durationMinutes: 15,
        tags: const <String>['work'],
        mood: 'Good',
        relatedHabits: const <String>['habit-1'],
      );

      final parsed = DailyEvent.fromJson(event.toJson());

      expect(parsed.toJson(), event.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final json = baseJson();

      final parsed = DailyEvent.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.eventType, '');
      expect(parsed.occurredAt, createdAt);
      expect(parsed.durationMinutes, isNull);
      expect(parsed.tags, isEmpty);
      expect(parsed.relatedHabits, isEmpty);
    });

    test('should tolerate wrong types when values are convertible', () {
      final json = baseJson()
        ..['durationMinutes'] = 15.0
        ..['tags'] = <dynamic>['work', 7];

      final parsed = DailyEvent.fromJson(json);

      expect(parsed.durationMinutes, 15);
      expect(parsed.tags, <String>['work']);
    });

    test('should fall back when dates are invalid', () {
      final json = baseJson()
        ..['occurredAt'] = 'not-a-date'
        ..['deletedAt'] = 'not-a-date';

      final parsed = DailyEvent.fromJson(json);

      expect(parsed.occurredAt, createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when createdAt is missing', () {
      final json = baseJson()..remove('createdAt');

      expect(() => DailyEvent.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
