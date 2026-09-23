import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/calendar/event.dart';
import 'package:abdalsalam/data/models/calendar/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

final _createdAt = DateTime.utc(2026, 2, 1, 8);
final _updatedAt = DateTime.utc(2026, 2, 2, 9);
final _deletedAt = DateTime.utc(2026, 2, 3, 10);
final _startTime = DateTime.utc(2026, 2, 5, 14);
final _endTime = DateTime.utc(2026, 2, 5, 15);
const _userId = 'user-1';

void main() {
  group('Event.fromJson', () {
    final event = Event(
      id: 'event-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      title: 'Dentist',
      description: 'Checkup',
      startTime: _startTime,
      endTime: _endTime,
      allDay: true,
      location: 'Nablus',
      attendees: const ['me'],
      reminderMinutes: const [10, 60],
      googleEventId: 'g-1',
      color: '#123456',
      category: 'health',
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = event.toJson();

      final parsed = Event.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'id': 'event-2',
        'createdAt': _createdAt.toIso8601String(),
        'startTime': _startTime.toIso8601String(),
      };

      final parsed = Event.fromJson(json);

      expect(parsed.title, '');
      expect(parsed.endTime, _startTime);
      expect(parsed.allDay, isFalse);
      expect(parsed.attendees, isEmpty);
      expect(parsed.reminderMinutes, isEmpty);
      expect(parsed.color, '#00897B');
      expect(parsed.category, 'general');
      expect(parsed.updatedAt, _createdAt);
    });

    test('should tolerate wrong types in lists and bools', () {
      final json = {
        ...event.toJson(),
        'reminderMinutes': [15.0, 'x', 30],
        'attendees': ['a', 3, 'b'],
        'allDay': 'true',
      };

      final parsed = Event.fromJson(json);

      expect(parsed.reminderMinutes, [15, 30]);
      expect(parsed.attendees, ['a', 'b']);
      expect(parsed.allDay, isTrue);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {
        ...event.toJson(),
        'updatedAt': 'bad',
        'deletedAt': 'bad',
        'endTime': 'bad',
      };

      final parsed = Event.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
      expect(parsed.endTime, _startTime);
    });

    test('should throw CorruptDataError when startTime is missing', () {
      final json = event.toJson()..remove('startTime');

      expect(() => Event.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = event.toJson()..remove('id');

      expect(() => Event.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('Reminder.fromJson', () {
    final reminder = Reminder(
      id: 'reminder-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      eventId: 'event-1',
      reminderTime: _startTime,
      type: ReminderType.email,
      sent: true,
      snoozedUntil: _endTime,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = reminder.toJson();

      final parsed = Reminder.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = <String, dynamic>{
        'id': 'reminder-2',
        'createdAt': _createdAt.toIso8601String(),
        'eventId': 'event-1',
        'reminderTime': _startTime.toIso8601String(),
      };

      final parsed = Reminder.fromJson(json);

      expect(parsed.type, ReminderType.notification);
      expect(parsed.sent, isFalse);
      expect(parsed.snoozedUntil, isNull);
      expect(parsed.updatedAt, _createdAt);
    });

    test('should tolerate an int for a bool field', () {
      final json = {...reminder.toJson(), 'sent': 0};

      final parsed = Reminder.fromJson(json);

      expect(parsed.sent, isFalse);
    });

    test('should return null when snoozedUntil is invalid', () {
      final json = {...reminder.toJson(), 'snoozedUntil': 'later', 'deletedAt': 'bad'};

      final parsed = Reminder.fromJson(json);

      expect(parsed.snoozedUntil, isNull);
      expect(parsed.deletedAt, isNull);
    });

    test('should fall back to notification when type is unknown', () {
      final json = {...reminder.toJson(), 'type': 'pigeon'};

      final parsed = Reminder.fromJson(json);

      expect(parsed.type, ReminderType.notification);
    });

    test('should throw CorruptDataError when eventId is missing', () {
      final json = reminder.toJson()..remove('eventId');

      expect(() => Reminder.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when reminderTime is invalid', () {
      final json = {...reminder.toJson(), 'reminderTime': 'soon'};

      expect(() => Reminder.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
