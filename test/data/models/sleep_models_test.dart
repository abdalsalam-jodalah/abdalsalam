import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 3, 1, 8);
  final createdAtText = createdAt.toIso8601String();

  Matcher throwsCorruptField(String field) =>
      throwsA(isA<CorruptDataError>().having((error) => error.field, 'field', field));

  Map<String, dynamic> minimalJson() => {
        'id': 'sleep-1',
        'createdAt': createdAtText,
        'sleepStart': '2026-02-28T23:00:00.000',
        'sleepEnd': '2026-03-01T07:00:00.000',
      };

  group('SleepLog.fromJson', () {
    final sleepLog = SleepLog(
      id: 'sleep-1',
      createdAt: createdAt,
      updatedAt: DateTime(2026, 3, 1, 9),
      userId: 'user',
      sleepStart: DateTime(2026, 2, 28, 23),
      sleepEnd: DateTime(2026, 3, 1, 7),
      nightWakeCount: 2,
      feelingBeforeSleep: 3,
      feelingBeforeSleepNote: 'tired',
      feelingOnWakeup: 4,
      feelingOnWakeupNote: 'rested',
      feelingDuringDay: 5,
      feelingDuringDayNote: 'focused',
      lastCaffeineTime: DateTime(2026, 2, 28, 15),
      notes: 'quiet night',
    );

    test('should keep every field when round tripping valid json', () {
      final parsed = SleepLog.fromJson(sleepLog.toJson());

      expect(parsed.toJson(), sleepLog.toJson());
      expect(parsed.duration, const Duration(hours: 8));
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = SleepLog.fromJson(minimalJson());

      expect(parsed.updatedAt, createdAt);
      expect(parsed.userId, '');
      expect(parsed.nightWakeCount, 0);
      expect(parsed.feelingOnWakeup, isNull);
      expect(parsed.lastCaffeineTime, isNull);
    });

    test('should tolerate wrong types when counts are stored as doubles or text', () {
      final parsed = SleepLog.fromJson({
        ...minimalJson(),
        'nightWakeCount': 3.0,
        'feelingOnWakeup': '4',
      });

      expect(parsed.nightWakeCount, 3);
      expect(parsed.feelingOnWakeup, 4);
    });

    test('should return null when lastCaffeineTime is malformed', () {
      final parsed = SleepLog.fromJson({...minimalJson(), 'lastCaffeineTime': 'afternoon'});

      expect(parsed.lastCaffeineTime, isNull);
    });

    test('should throw CorruptDataError when sleepStart is missing', () {
      expect(() => SleepLog.fromJson(minimalJson()..remove('sleepStart')), throwsCorruptField('sleepStart'));
    });

    test('should throw CorruptDataError when sleepEnd is malformed', () {
      expect(
        () => SleepLog.fromJson({...minimalJson(), 'sleepEnd': 'morning'}),
        throwsCorruptField('sleepEnd'),
      );
    });
  });
}
