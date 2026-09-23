import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/sports/body_measurement.dart';
import 'package:abdalsalam/data/models/sports/exercise.dart';
import 'package:abdalsalam/data/models/sports/exercise_category.dart';
import 'package:abdalsalam/data/models/sports/exercise_log.dart';
import 'package:abdalsalam/data/models/sports/exercise_set_log.dart';
import 'package:abdalsalam/data/models/sports/weekly_schedule_entry.dart';
import 'package:flutter_test/flutter_test.dart';

final _createdAt = DateTime.utc(2026, 1, 10, 8);
final _updatedAt = DateTime.utc(2026, 1, 11, 9);
final _deletedAt = DateTime.utc(2026, 1, 12, 10);
final _loggedDate = DateTime.utc(2026, 1, 9);
const _userId = 'user-1';

Map<String, dynamic> _minimalBase(String id) => <String, dynamic>{
      'id': id,
      'createdAt': _createdAt.toIso8601String(),
    };

void main() {
  group('BodyMeasurement.fromJson', () {
    final measurement = BodyMeasurement(
      id: 'bm-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      date: _loggedDate,
      weightKg: 81.5,
      heightCm: 180,
      bodyFatPercent: 18.2,
      chestCm: 100,
      waistCm: 85,
      abdominalCm: 88,
      hipsCm: 98,
      thighCm: 58,
      armCm: 36,
      notes: 'morning',
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = measurement.toJson();

      final parsed = BodyMeasurement.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = {
        ..._minimalBase('bm-2'),
        'date': _loggedDate.toIso8601String(),
        'weightKg': 80,
      };

      final parsed = BodyMeasurement.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
      expect(parsed.userId, '');
      expect(parsed.heightCm, isNull);
      expect(parsed.notes, isNull);
    });

    test('should tolerate numeric strings and ints for double fields', () {
      final json = {...measurement.toJson(), 'weightKg': '82.5', 'heightCm': 181};

      final parsed = BodyMeasurement.fromJson(json);

      expect(parsed.weightKg, 82.5);
      expect(parsed.heightCm, 181.0);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...measurement.toJson(), 'updatedAt': 'not-a-date', 'deletedAt': 'bad'};

      final parsed = BodyMeasurement.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when weightKg is missing', () {
      final json = measurement.toJson()..remove('weightKg');

      expect(() => BodyMeasurement.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when date is invalid', () {
      final json = {...measurement.toJson(), 'date': 'yesterday'};

      expect(() => BodyMeasurement.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when id is missing', () {
      final json = measurement.toJson()..remove('id');

      expect(() => BodyMeasurement.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('ExerciseCategory.fromJson', () {
    final category = ExerciseCategory(
      id: 'cat-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      name: 'Chest',
      colorHex: '#FF0000',
      order: 2,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = category.toJson();

      final parsed = ExerciseCategory.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = ExerciseCategory.fromJson(_minimalBase('cat-2'));

      expect(parsed.name, '');
      expect(parsed.colorHex, isNull);
      expect(parsed.order, 0);
      expect(parsed.updatedAt, _createdAt);
    });

    test('should tolerate a double for an int field', () {
      final json = {...category.toJson(), 'order': 3.0};

      final parsed = ExerciseCategory.fromJson(json);

      expect(parsed.order, 3);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...category.toJson(), 'updatedAt': 12.5, 'deletedAt': 'bad'};

      final parsed = ExerciseCategory.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when createdAt is missing', () {
      final json = category.toJson()..remove('createdAt');

      expect(() => ExerciseCategory.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('Exercise.fromJson', () {
    final exercise = Exercise(
      id: 'ex-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      name: 'Bench press',
      categoryId: 'cat-1',
      trackingType: ExerciseTrackingType.reps,
      difficulty: ExerciseDifficulty.advanced,
      equipment: 'Barbell',
      defaultSets: 4,
      defaultReps: 8,
      defaultWeightKg: 60,
      instructions: 'Keep elbows tucked',
      notes: 'PR attempt',
      order: 1,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = exercise.toJson();

      final parsed = Exercise.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = {
        ..._minimalBase('ex-2'),
        'categoryId': 'cat-1',
        'trackingType': 'cardio',
      };

      final parsed = Exercise.fromJson(json);

      expect(parsed.name, '');
      expect(parsed.difficulty, ExerciseDifficulty.intermediate);
      expect(parsed.defaultSets, isNull);
      expect(parsed.order, 0);
    });

    test('should tolerate wrong numeric types', () {
      final json = {...exercise.toJson(), 'defaultSets': 5.0, 'defaultWeightKg': '62.5'};

      final parsed = Exercise.fromJson(json);

      expect(parsed.defaultSets, 5);
      expect(parsed.defaultWeightKg, 62.5);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...exercise.toJson(), 'updatedAt': 'bad', 'deletedAt': 'bad'};

      final parsed = Exercise.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should fall back to intermediate when difficulty is unknown', () {
      final json = {...exercise.toJson(), 'difficulty': 'legendary'};

      final parsed = Exercise.fromJson(json);

      expect(parsed.difficulty, ExerciseDifficulty.intermediate);
    });

    test('should throw CorruptDataError when trackingType is unknown', () {
      final json = {...exercise.toJson(), 'trackingType': 'swimming'};

      expect(() => Exercise.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when categoryId is missing', () {
      final json = exercise.toJson()..remove('categoryId');

      expect(() => Exercise.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('ExerciseLog.fromJson', () {
    final log = ExerciseLog(
      id: 'log-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      date: _loggedDate,
      exerciseId: 'ex-1',
      order: 2,
      scheduleEntryId: 'sched-1',
      notes: 'felt strong',
      steps: 4000,
      durationSeconds: 1800,
      distanceKm: 3.2,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = log.toJson();

      final parsed = ExerciseLog.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = {
        ..._minimalBase('log-2'),
        'date': _loggedDate.toIso8601String(),
        'exerciseId': 'ex-1',
      };

      final parsed = ExerciseLog.fromJson(json);

      expect(parsed.order, 0);
      expect(parsed.scheduleEntryId, isNull);
      expect(parsed.steps, isNull);
      expect(parsed.distanceKm, isNull);
    });

    test('should tolerate wrong numeric types', () {
      final json = {...log.toJson(), 'steps': 4200.0, 'durationSeconds': '900', 'distanceKm': 5};

      final parsed = ExerciseLog.fromJson(json);

      expect(parsed.steps, 4200);
      expect(parsed.durationSeconds, 900);
      expect(parsed.distanceKm, 5.0);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...log.toJson(), 'updatedAt': 'bad', 'deletedAt': 'bad'};

      final parsed = ExerciseLog.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when exerciseId is missing', () {
      final json = log.toJson()..remove('exerciseId');

      expect(() => ExerciseLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when date is invalid', () {
      final json = {...log.toJson(), 'date': 'someday'};

      expect(() => ExerciseLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('ExerciseSetLog.fromJson', () {
    final setLog = ExerciseSetLog(
      id: 'set-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      exerciseLogId: 'log-1',
      setNumber: 2,
      reps: 10,
      weightKg: 40,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = setLog.toJson();

      final parsed = ExerciseSetLog.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = {..._minimalBase('set-2'), 'exerciseLogId': 'log-1', 'reps': 8};

      final parsed = ExerciseSetLog.fromJson(json);

      expect(parsed.setNumber, 0);
      expect(parsed.weightKg, isNull);
      expect(parsed.userId, '');
    });

    test('should tolerate wrong numeric types', () {
      final json = {...setLog.toJson(), 'reps': 12.0, 'setNumber': '3', 'weightKg': '42.5'};

      final parsed = ExerciseSetLog.fromJson(json);

      expect(parsed.reps, 12);
      expect(parsed.setNumber, 3);
      expect(parsed.weightKg, 42.5);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...setLog.toJson(), 'updatedAt': 'bad', 'deletedAt': 'bad'};

      final parsed = ExerciseSetLog.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when reps is missing', () {
      final json = setLog.toJson()..remove('reps');

      expect(() => ExerciseSetLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when exerciseLogId is missing', () {
      final json = setLog.toJson()..remove('exerciseLogId');

      expect(() => ExerciseSetLog.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });

  group('WeeklyScheduleEntry.fromJson', () {
    final entry = WeeklyScheduleEntry(
      id: 'sched-1',
      createdAt: _createdAt,
      updatedAt: _updatedAt,
      deletedAt: _deletedAt,
      userId: _userId,
      dayOfWeek: DateTime.monday,
      exerciseId: 'ex-1',
      order: 1,
      enabled: false,
    );

    test('should keep every field when round-tripping through toJson', () {
      final json = entry.toJson();

      final parsed = WeeklyScheduleEntry.fromJson(json);

      expect(parsed.toJson(), json);
    });

    test('should use defaults when optional fields are missing', () {
      final json = {..._minimalBase('sched-2'), 'dayOfWeek': DateTime.friday, 'exerciseId': 'ex-1'};

      final parsed = WeeklyScheduleEntry.fromJson(json);

      expect(parsed.order, 0);
      expect(parsed.enabled, isTrue);
    });

    test('should tolerate wrong types for int and bool fields', () {
      final json = {...entry.toJson(), 'dayOfWeek': 3.0, 'enabled': 1};

      final parsed = WeeklyScheduleEntry.fromJson(json);

      expect(parsed.dayOfWeek, 3);
      expect(parsed.enabled, isTrue);
    });

    test('should fall back when optional dates are invalid', () {
      final json = {...entry.toJson(), 'updatedAt': 'bad', 'deletedAt': 'bad'};

      final parsed = WeeklyScheduleEntry.fromJson(json);

      expect(parsed.updatedAt, _createdAt);
      expect(parsed.deletedAt, isNull);
    });

    test('should throw CorruptDataError when dayOfWeek is missing', () {
      final json = entry.toJson()..remove('dayOfWeek');

      expect(() => WeeklyScheduleEntry.fromJson(json), throwsA(isA<CorruptDataError>()));
    });

    test('should throw CorruptDataError when exerciseId is missing', () {
      final json = entry.toJson()..remove('exerciseId');

      expect(() => WeeklyScheduleEntry.fromJson(json), throwsA(isA<CorruptDataError>()));
    });
  });
}
