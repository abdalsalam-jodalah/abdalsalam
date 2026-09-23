import 'package:abdalsalam/data/models/health/medication_log.dart';
import 'package:abdalsalam/data/repositories/health/medication_log_repository.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  final day = DateTime(2026, 3, 1);
  late MedicationLogRepositoryImpl repository;

  MedicationLog log(String id, {String medicationId = 'med-1', String time = '08:00', DateTime? scheduledFor}) {
    return MedicationLog(
      id: id,
      createdAt: day,
      updatedAt: day,
      userId: 'user',
      medicationId: medicationId,
      scheduledFor: scheduledFor ?? DateTime(2026, 3, 1, 8),
      scheduledTime: time,
    );
  }

  Future<void> insertRowMissingScheduledTime(String id) async {
    await storage.upsertRecord(
      table: repository.tableName,
      id: id,
      record: {
        'createdAt': day.toIso8601String(),
        'medicationId': 'med-1',
        'scheduledFor': DateTime(2026, 3, 1, 8).toIso8601String(),
      },
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_medication_log_repository_test.db');
    repository = MedicationLogRepositoryImpl(storage, LoggerService.forModule('MedicationLogRepositoryTest'));
    await storage.clearTable(repository.tableName);
    storage.integrityReporter.clearReports();
  });

  group('MedicationLogRepositoryImpl.getByMedicationId', () {
    test('should skip a corrupt row instead of failing the query', () async {
      await repository.create(log('good'));
      await insertRowMissingScheduledTime('broken');

      final result = await repository.getByMedicationId('med-1');

      expect(result.isSuccess, isTrue);
      expect(result.data?.map((entity) => entity.id), ['good']);
      expect(storage.integrityReporter.reports.single.recordId, 'broken');
    });

    test('should return only logs for the requested medication', () async {
      await repository.create(log('a'));
      await repository.create(log('b', medicationId: 'med-2'));

      final result = await repository.getByMedicationId('med-2');

      expect(result.data?.map((entity) => entity.id), ['b']);
    });
  });

  group('MedicationLogRepositoryImpl.getLogForMedicationAndTime', () {
    test('should return the log when one matches the day and time', () async {
      await repository.create(log('morning'));
      await repository.create(log('evening', time: '20:00', scheduledFor: DateTime(2026, 3, 1, 20)));

      final result = await repository.getLogForMedicationAndTime('med-1', day, '20:00');

      expect(result.data?.id, 'evening');
    });

    test('should return null when no log matches', () async {
      await repository.create(log('morning'));

      final result = await repository.getLogForMedicationAndTime('med-1', DateTime(2026, 3, 2), '08:00');

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });

  group('MedicationLogRepositoryImpl.getByDate', () {
    test('should return logs for the day sorted by time and skip corrupt rows', () async {
      await repository.create(log('evening', time: '20:00', scheduledFor: DateTime(2026, 3, 1, 20)));
      await repository.create(log('morning'));
      await repository.create(log('next-day', scheduledFor: DateTime(2026, 3, 2, 8)));
      await insertRowMissingScheduledTime('broken');

      final result = await repository.getByDate(day);

      expect(result.data?.map((entity) => entity.id), ['morning', 'evening']);
    });

    test('should return only pending logs from getPendingForDate', () async {
      await repository.create(log('pending'));
      await repository.create(log('taken', time: '09:00').copyWith(takenAt: DateTime(2026, 3, 1, 9)));

      final result = await repository.getPendingForDate(day);

      expect(result.data?.map((entity) => entity.id), ['pending']);
    });
  });
}
