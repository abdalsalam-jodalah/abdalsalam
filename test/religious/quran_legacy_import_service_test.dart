import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/quran_progress.dart';
import 'package:abdalsalam/data/models/religious/quran_reading.dart';
import 'package:abdalsalam/data/repositories/religious/quran_reading_repository.dart';
import 'package:abdalsalam/data/repositories/religious/quran_repository.dart';
import 'package:abdalsalam/features/religious/services/quran_legacy_import_service.dart';
import 'package:abdalsalam/features/religious/services/quran_reading_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FailingBulkReadingRepository extends QuranReadingRepository {
  FailingBulkReadingRepository(super.storage, super.logger);

  @override
  Future<Result<List<QuranReading>, AppError>> createBulk(List<QuranReading> entities) async {
    return Failure(DatabaseError('disk full'));
  }
}

class FailingLegacyRepository extends QuranRepository {
  FailingLegacyRepository(super.storage, super.logger);

  @override
  Future<Result<List<QuranProgress>, AppError>> getAll() async {
    return Failure(DatabaseError('legacy table unreadable'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final storage = StorageGateway.instance;
  late LoggerService logger;
  late QuranRepository legacyRepository;
  late QuranReadingRepository readingRepository;

  QuranProgress legacy(String id, {int pagesRead = 5, int minutesSpent = 20, DateTime? deletedAt}) {
    return QuranProgress(
      id: id,
      createdAt: DateTime(2025, 3, 1, 8),
      updatedAt: DateTime(2025, 3, 1, 8),
      deletedAt: deletedAt,
      userId: 'local-user',
      pagesRead: pagesRead,
      minutesSpent: minutesSpent,
      loggedAt: DateTime(2025, 3, 1, 7, 30),
    );
  }

  QuranLegacyImportService buildService({
    QuranRepository? legacy,
    QuranReadingRepository? readings,
  }) {
    return QuranLegacyImportService(
      legacyRepository: legacy ?? legacyRepository,
      readingService: QuranReadingService(readings ?? readingRepository, logger),
      logger: logger,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    await storage.initialize(databaseName: 'test_quran_legacy_import_service_test.db');
    await DatabaseSchemaInitializer.initialize(storage);
    await storage.clearTable('quran_progress');
    await storage.clearTable('quran_readings');
    logger = LoggerService.forModule('QuranLegacyImportTest');
    legacyRepository = QuranRepository(storage, logger);
    readingRepository = QuranReadingRepository(storage, logger);
  });

  group('QuranLegacyImportService', () {
    test('should import legacy progress as unknown-passage readings', () async {
      await legacyRepository.create(legacy('legacy-1'));
      final service = buildService();

      final result = await service.importLegacyProgress();

      expect(result.isSuccess, isTrue);
      expect(result.data!.importedCount, 1);
      final readings = (await readingRepository.getAll()).data!;
      expect(readings, hasLength(1));
      final reading = readings.single;
      expect(reading.id, 'legacy-1');
      expect(reading.surahNumber, QuranReadingService.unknownSurahNumber);
      expect(reading.ayahFrom, QuranReadingService.unknownAyahNumber);
      expect(reading.ayahTo, QuranReadingService.unknownAyahNumber);
      expect(reading.pagesRead, 5);
      expect(reading.durationMinutes, 20);
      expect(reading.readAt, DateTime(2025, 3, 1, 7, 30));
    });

    test('should skip and report entries that cannot be mapped', () async {
      await legacyRepository.create(legacy('valid'));
      await legacyRepository.create(legacy('no-duration', minutesSpent: 0));
      await legacyRepository.create(legacy('deleted', deletedAt: DateTime(2025, 4)));
      final service = buildService();

      final result = await service.importLegacyProgress();

      expect(result.isSuccess, isTrue);
      expect(result.data!.importedCount, 1);
      expect(result.data!.skippedLegacyIds, unorderedEquals(<String>['no-duration', 'deleted']));
      expect(result.data!.hasSkippedEntries, isTrue);
      expect((await readingRepository.getAll()).data!.map((reading) => reading.id), ['valid']);
    });

    test('should not duplicate readings when the import runs twice', () async {
      await legacyRepository.create(legacy('legacy-1'));
      final service = buildService();
      await service.importLegacyProgress();

      final second = await service.importLegacyProgress();

      expect(second.isSuccess, isTrue);
      expect(second.data!.importedCount, 0);
      expect(second.data!.alreadyImportedCount, 1);
      expect((await readingRepository.getAll()).data!, hasLength(1));
    });

    test('should return failure and write nothing when the bulk write fails', () async {
      await legacyRepository.create(legacy('legacy-1'));
      await legacyRepository.create(legacy('legacy-2'));
      final service = buildService(readings: FailingBulkReadingRepository(storage, logger));

      final result = await service.importLegacyProgress();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
      expect((await readingRepository.getAll()).data!, isEmpty);
    });

    test('should return failure when legacy progress cannot be read', () async {
      final service = buildService(legacy: FailingLegacyRepository(storage, logger));

      final result = await service.importLegacyProgress();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
    });
  });

  group('QuranReadingService.validate', () {
    QuranReading reading({required int surah, required int ayahFrom, required int ayahTo}) {
      return QuranReading(
        id: 'r1',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        userId: 'local-user',
        surahNumber: surah,
        ayahFrom: ayahFrom,
        ayahTo: ayahTo,
        readAt: DateTime(2026),
        durationMinutes: 10,
        memorized: false,
        pagesRead: 2,
      );
    }

    test('should accept an unknown passage recorded as surah 0 ayah 0-0', () {
      final service = QuranReadingService(readingRepository, logger);

      final result = service.validate(reading(surah: 0, ayahFrom: 0, ayahTo: 0));

      expect(result.isSuccess, isTrue);
    });

    test('should reject surah 0 when an ayah range is given', () {
      final service = QuranReadingService(readingRepository, logger);

      final result = service.validate(reading(surah: 0, ayahFrom: 1, ayahTo: 7));

      expect(result.isFailure, isTrue);
      expect(result.error, isA<ValidationError>());
    });

    test('should reject surah numbers above 114', () {
      final service = QuranReadingService(readingRepository, logger);

      final result = service.validate(reading(surah: 115, ayahFrom: 1, ayahTo: 2));

      expect(result.isFailure, isTrue);
    });
  });
}
