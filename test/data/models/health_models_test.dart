import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/data/models/health/blood_test.dart';
import 'package:abdalsalam/data/models/health/doctor_visit.dart';
import 'package:abdalsalam/data/models/health/health_metric.dart';
import 'package:abdalsalam/data/models/health/medication.dart';
import 'package:abdalsalam/data/models/health/medication_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 3, 1, 8);
  final updatedAt = DateTime(2026, 3, 2, 9);
  final createdAtText = createdAt.toIso8601String();

  Matcher throwsCorruptField(String field) =>
      throwsA(isA<CorruptDataError>().having((error) => error.field, 'field', field));

  group('BloodTest.fromJson', () {
    final bloodTest = BloodTest(
      id: 'blood-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: 'user',
      testType: 'CBC',
      scheduledDate: DateTime(2026, 3, 10),
      completedDate: DateTime(2026, 3, 11),
      results: const {'hemoglobin': 14.2},
      notes: 'fasting',
      nextTestDate: DateTime(2026, 9, 10),
      facility: 'Lab',
    );

    test('should keep every field when round tripping valid json', () {
      final parsed = BloodTest.fromJson(bloodTest.toJson());

      expect(parsed.toJson(), bloodTest.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = BloodTest.fromJson({'id': 'blood-1', 'createdAt': createdAtText});

      expect(parsed.updatedAt, createdAt);
      expect(parsed.testType, '');
      expect(parsed.scheduledDate, createdAt);
      expect(parsed.results, isEmpty);
      expect(parsed.completedDate, isNull);
    });

    test('should tolerate wrong types when fields hold unexpected values', () {
      final parsed = BloodTest.fromJson({
        'id': 'blood-1',
        'createdAt': createdAtText,
        'testType': 42,
        'results': 'not a map',
      });

      expect(parsed.testType, '42');
      expect(parsed.results, isEmpty);
    });

    test('should return null when an optional date is malformed', () {
      final parsed = BloodTest.fromJson({
        'id': 'blood-1',
        'createdAt': createdAtText,
        'completedDate': 'not a date',
        'scheduledDate': 'not a date',
      });

      expect(parsed.completedDate, isNull);
      expect(parsed.scheduledDate, createdAt);
    });

    test('should throw CorruptDataError when id is missing', () {
      expect(() => BloodTest.fromJson({'createdAt': createdAtText}), throwsCorruptField('id'));
    });
  });

  group('DoctorVisit.fromJson', () {
    final visit = DoctorVisit(
      id: 'visit-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: 'user',
      doctorName: 'Dr. Ali',
      specialty: 'Cardiology',
      visitDate: DateTime(2026, 4, 1),
      reason: 'Checkup',
      diagnosis: 'Healthy',
      medicationIds: const ['med-1'],
      attachmentPaths: const ['/tmp/report.pdf'],
      followUpDate: DateTime(2026, 10, 1),
      notes: 'bring results',
    );

    test('should keep every field when round tripping valid json', () {
      final parsed = DoctorVisit.fromJson(visit.toJson());

      expect(parsed, visit);
      expect(parsed.toJson(), visit.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = DoctorVisit.fromJson({'id': 'visit-1', 'createdAt': createdAtText});

      expect(parsed.doctorName, '');
      expect(parsed.reason, '');
      expect(parsed.visitDate, createdAt);
      expect(parsed.medicationIds, isEmpty);
      expect(parsed.attachmentPaths, isEmpty);
    });

    test('should drop wrong-typed list items when lists hold mixed values', () {
      final parsed = DoctorVisit.fromJson({
        'id': 'visit-1',
        'createdAt': createdAtText,
        'medicationIds': ['med-1', 7, null],
      });

      expect(parsed.medicationIds, ['med-1']);
    });

    test('should return null when an optional date is malformed', () {
      final parsed = DoctorVisit.fromJson({
        'id': 'visit-1',
        'createdAt': createdAtText,
        'followUpDate': 'soon',
      });

      expect(parsed.followUpDate, isNull);
    });

    test('should throw CorruptDataError when createdAt is missing', () {
      expect(() => DoctorVisit.fromJson({'id': 'visit-1'}), throwsCorruptField('createdAt'));
    });
  });

  group('HealthMetric.fromJson', () {
    final metric = HealthMetric(
      id: 'metric-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: 'user',
      metricType: 'weight',
      value: 72.5,
      unit: 'kg',
      measuredAt: DateTime(2026, 3, 1, 7),
      notes: 'morning',
    );

    Map<String, dynamic> minimalJson() => {
          'id': 'metric-1',
          'createdAt': createdAtText,
          'metricType': 'weight',
          'value': 72.5,
        };

    test('should keep every field when round tripping valid json', () {
      final parsed = HealthMetric.fromJson(metric.toJson());

      expect(parsed.toJson(), metric.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = HealthMetric.fromJson(minimalJson());

      expect(parsed.unit, '');
      expect(parsed.measuredAt, createdAt);
      expect(parsed.notes, isNull);
    });

    test('should accept a numeric string when value is stored as text', () {
      final parsed = HealthMetric.fromJson({...minimalJson(), 'value': '72.5'});

      expect(parsed.value, 72.5);
    });

    test('should fall back to createdAt when measuredAt is malformed', () {
      final parsed = HealthMetric.fromJson({...minimalJson(), 'measuredAt': 'yesterday'});

      expect(parsed.measuredAt, createdAt);
    });

    test('should throw CorruptDataError when value is missing', () {
      expect(() => HealthMetric.fromJson(minimalJson()..remove('value')), throwsCorruptField('value'));
    });

    test('should throw CorruptDataError when metricType is missing', () {
      expect(
        () => HealthMetric.fromJson(minimalJson()..remove('metricType')),
        throwsCorruptField('metricType'),
      );
    });
  });

  group('Medication.fromJson', () {
    final medication = Medication(
      id: 'med-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: 'user',
      name: 'Vitamin D',
      dosage: '1000 IU',
      frequency: 'daily',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 6, 1),
      reminderTimes: const ['08:00', '20:00'],
      prescribedBy: 'Dr. Ali',
      notes: 'with food',
      refillDate: DateTime(2026, 4, 1),
      displayOrder: 2,
      isActive: false,
      timing: MedicationTiming.withMeal,
      weekDays: const [WeekDay.friday, WeekDay.monday],
    );

    Map<String, dynamic> minimalJson() => {
          'id': 'med-1',
          'createdAt': createdAtText,
          'name': 'Vitamin D',
          'dosage': '1000 IU',
        };

    test('should keep every field when round tripping valid json', () {
      final parsed = Medication.fromJson(medication.toJson());

      expect(parsed, medication);
      expect(parsed.toJson(), medication.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = Medication.fromJson(minimalJson());

      expect(parsed.frequency, '');
      expect(parsed.startDate, createdAt);
      expect(parsed.reminderTimes, isEmpty);
      expect(parsed.displayOrder, 0);
      expect(parsed.isActive, isTrue);
      expect(parsed.timing, MedicationTiming.anytime);
      expect(parsed.weekDays, isEmpty);
    });

    test('should tolerate wrong types when numbers and flags are stored loosely', () {
      final parsed = Medication.fromJson({...minimalJson(), 'displayOrder': 3.0, 'isActive': 0});

      expect(parsed.displayOrder, 3);
      expect(parsed.isActive, isFalse);
    });

    test('should return null when an optional date is malformed', () {
      final parsed = Medication.fromJson({...minimalJson(), 'endDate': 'never', 'refillDate': 'soon'});

      expect(parsed.endDate, isNull);
      expect(parsed.refillDate, isNull);
    });

    test('should fall back to anytime when timing is unknown', () {
      final parsed = Medication.fromJson({...minimalJson(), 'timing': 'midnightSnack'});

      expect(parsed.timing, MedicationTiming.anytime);
    });

    test('should throw CorruptDataError when a week day is unknown', () {
      expect(
        () => Medication.fromJson({...minimalJson(), 'weekDays': ['monday', 'funday']}),
        throwsCorruptField('weekDays'),
      );
    });

    test('should default dosage to empty when it is missing', () {
      expect(Medication.fromJson(minimalJson()..remove('dosage')).dosage, isEmpty);
    });

    test('should throw CorruptDataError when name is missing', () {
      expect(() => Medication.fromJson(minimalJson()..remove('name')), throwsCorruptField('name'));
    });
  });

  group('MedicationLog.fromJson', () {
    final log = MedicationLog(
      id: 'log-1',
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: 'user',
      medicationId: 'med-1',
      scheduledFor: DateTime(2026, 3, 1, 8),
      scheduledTime: '08:00',
      takenAt: DateTime(2026, 3, 1, 8, 5),
      skipped: true,
      skipReason: 'nausea',
      sideEffects: 'none',
      notes: 'late',
    );

    Map<String, dynamic> minimalJson() => {
          'id': 'log-1',
          'createdAt': createdAtText,
          'medicationId': 'med-1',
          'scheduledFor': '2026-03-01T08:00:00.000',
          'scheduledTime': '08:00',
        };

    test('should keep every field when round tripping valid json', () {
      final parsed = MedicationLog.fromJson(log.toJson());

      expect(parsed, log);
      expect(parsed.toJson(), log.toJson());
    });

    test('should use defaults when optional fields are missing', () {
      final parsed = MedicationLog.fromJson(minimalJson());

      expect(parsed.updatedAt, createdAt);
      expect(parsed.userId, '');
      expect(parsed.skipped, isFalse);
      expect(parsed.isPending, isTrue);
    });

    test('should tolerate wrong types when skipped is stored as text', () {
      final parsed = MedicationLog.fromJson({...minimalJson(), 'skipped': 'true'});

      expect(parsed.skipped, isTrue);
    });

    test('should return null when takenAt is malformed', () {
      final parsed = MedicationLog.fromJson({...minimalJson(), 'takenAt': 'earlier'});

      expect(parsed.takenAt, isNull);
    });

    test('should throw CorruptDataError when medicationId is missing', () {
      expect(
        () => MedicationLog.fromJson(minimalJson()..remove('medicationId')),
        throwsCorruptField('medicationId'),
      );
    });

    test('should throw CorruptDataError when scheduledFor is malformed', () {
      expect(
        () => MedicationLog.fromJson({...minimalJson(), 'scheduledFor': 'morning'}),
        throwsCorruptField('scheduledFor'),
      );
    });

    test('should throw CorruptDataError when scheduledTime is missing', () {
      expect(
        () => MedicationLog.fromJson(minimalJson()..remove('scheduledTime')),
        throwsCorruptField('scheduledTime'),
      );
    });
  });
}
