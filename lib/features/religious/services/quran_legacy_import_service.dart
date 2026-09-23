import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/quran_progress.dart';
import '../../../data/models/religious/quran_reading.dart';
import '../../../data/repositories/base_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import 'quran_legacy_import_report.dart';
import 'quran_reading_service.dart';

class QuranLegacyImportService {
  static const _logTag = '[QuranLegacyImport]';

  final BaseRepository<QuranProgress> legacyRepository;
  final QuranReadingService readingService;
  final LoggerService logger;

  const QuranLegacyImportService({
    required this.legacyRepository,
    required this.readingService,
    required this.logger,
  });

  Future<Result<QuranLegacyImportReport, AppError>> importLegacyProgress() async {
    final legacyResult = await legacyRepository.getAll();
    if (legacyResult.isFailure) {
      logger.warning('$_logTag reading legacy progress failed: ${legacyResult.error}');
      return Failure(legacyResult.error!);
    }

    final existingResult = await readingService.getAll();
    if (existingResult.isFailure) {
      logger.warning('$_logTag reading existing readings failed: ${existingResult.error}');
      return Failure(existingResult.error!);
    }
    final existingIds = existingResult.data!.map((reading) => reading.id).toSet();

    final readings = <QuranReading>[];
    final skippedLegacyIds = <String>[];
    var alreadyImportedCount = 0;
    for (final legacy in legacyResult.data!) {
      if (existingIds.contains(legacy.id)) {
        alreadyImportedCount += 1;
        continue;
      }
      final reading = _toReading(legacy);
      if (reading == null) {
        skippedLegacyIds.add(legacy.id);
        continue;
      }
      readings.add(reading);
    }

    if (skippedLegacyIds.isNotEmpty) {
      logger.warning('$_logTag skipped ${skippedLegacyIds.length} unmappable entries: ${skippedLegacyIds.join(', ')}');
    }

    if (readings.isNotEmpty) {
      final created = await readingService.createBulk(readings);
      if (created.isFailure) {
        return Failure(created.error!);
      }
    }

    logger.info('$_logTag imported ${readings.length}, already imported $alreadyImportedCount');
    return Success(
      QuranLegacyImportReport(
        importedCount: readings.length,
        alreadyImportedCount: alreadyImportedCount,
        skippedLegacyIds: List<String>.unmodifiable(skippedLegacyIds),
      ),
    );
  }

  QuranReading? _toReading(QuranProgress legacy) {
    if (legacy.isDeleted) {
      return null;
    }
    final reading = QuranReading(
      id: legacy.id,
      createdAt: legacy.createdAt,
      updatedAt: legacy.updatedAt,
      userId: legacy.userId,
      surahNumber: QuranReadingService.unknownSurahNumber,
      ayahFrom: QuranReadingService.unknownAyahNumber,
      ayahTo: QuranReadingService.unknownAyahNumber,
      readAt: legacy.loggedAt,
      durationMinutes: legacy.minutesSpent,
      memorized: false,
      pagesRead: legacy.pagesRead,
    );
    return readingService.validate(reading).isSuccess ? reading : null;
  }
}
