import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/health/services/medication_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final day = DateTime(2026, 3, 1);
  late FakeHealthRepository medications;
  late FakeMedicationLogRepository logs;
  late MedicationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    medications = FakeHealthRepository([buildMedication()]);
    logs = FakeMedicationLogRepository();
    service = MedicationService(
      repository: medications,
      logger: LoggerService.forModule('MedicationServiceTest'),
      logRepository: logs,
    );
  });

  group('MedicationService.generateDailyLogs', () {
    test('should create one log per reminder time when none exist', () async {
      final result = await service.generateDailyLogs(day, 'user');

      expect(result.isSuccess, isTrue);
      expect(logs.items.single.medicationId, 'med-1');
    });

    test('should return Failure when saving the new logs fails', () async {
      logs.shouldFailCreateBulk = true;

      final result = await service.generateDailyLogs(day, 'user');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });

    test('should return Failure instead of skipping when the existing-log lookup fails', () async {
      logs.shouldFailLookup = true;

      final result = await service.generateDailyLogs(day, 'user');

      expect(result.isFailure, isTrue);
      expect(logs.items, isEmpty);
    });
  });

  group('MedicationService.markAsTaken', () {
    test('should return the updated log when the save succeeds', () async {
      logs.items.add(buildMedicationLog(scheduledFor: day));

      final result = await service.markAsTaken('med-1', day, '08:00');

      expect(result.isSuccess, isTrue);
      expect(result.data?.isTaken, isTrue);
    });

    test('should return Failure when the log update fails', () async {
      logs.items.add(buildMedicationLog(scheduledFor: day));
      logs.shouldFailUpdate = true;

      final result = await service.markAsTaken('med-1', day, '08:00');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });
  });

  group('MedicationService.resetDailyLogs', () {
    test('should return Failure when the bulk update fails', () async {
      logs.items.add(buildMedicationLog(scheduledFor: day));
      logs.shouldFailUpdateBulk = true;

      final result = await service.resetDailyLogs(day);

      expect(result.isFailure, isTrue);
    });
  });

  group('MedicationService.reorderMedications', () {
    test('should save the new display order', () async {
      medications.items.add(buildMedication(id: 'med-2', displayOrder: 1));

      final result = await service.reorderMedications(['med-2', 'med-1']);

      expect(result.isSuccess, isTrue);
      expect(medications.items.where((m) => m.id == 'med-2').single.displayOrder, 0);
    });

    test('should return Failure when the bulk update fails', () async {
      medications.shouldFailUpdateBulk = true;

      final result = await service.reorderMedications(['med-1']);

      expect(result.isFailure, isTrue);
    });

    test('should return Failure when a medication lookup fails', () async {
      medications.shouldFailGetById = true;

      final result = await service.reorderMedications(['med-1']);

      expect(result.isFailure, isTrue);
    });

    test('should map a thrown exception to a ServiceError instead of throwing', () async {
      medications.shouldThrowOnGetById = true;

      final result = await service.reorderMedications(['med-1']);

      expect(result.error, isA<ServiceError>());
    });
  });

  group('MedicationService.toggleActive', () {
    test('should flip the active flag when the save succeeds', () async {
      final result = await service.toggleActive('med-1');

      expect(result.data?.isActive, isFalse);
    });

    test('should return Failure when the update fails', () async {
      medications.shouldFailUpdate = true;

      final result = await service.toggleActive('med-1');

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });

    test('should return NotFoundError when the medication does not exist', () async {
      final result = await service.toggleActive('missing');

      expect(result.error, isA<NotFoundError>());
    });

    test('should propagate the lookup failure instead of reporting not found', () async {
      medications.shouldFailGetById = true;

      final result = await service.toggleActive('med-1');

      expect(result.error, isA<DatabaseError>());
    });
  });

  group('MedicationService.getDailyChecklist', () {
    test('should return Failure when a medication lookup fails', () async {
      logs.items.add(buildMedicationLog(scheduledFor: day));
      medications.shouldFailGetById = true;

      final result = await service.getDailyChecklist(day);

      expect(result.isFailure, isTrue);
    });
  });
}
