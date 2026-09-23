import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/religious/quran_reading.dart';
import '../../../data/repositories/religious/quran_reading_repository.dart';
import '../../../providers/app_providers.dart';
import '../services/quran_legacy_import_service.dart';
import '../services/quran_reading_service.dart';
import 'prayer_providers.dart';
import 'quran_providers.dart';

final quranReadingRepositoryProvider = Provider<QuranReadingRepository>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return QuranReadingRepository(storage, logger);
});

final quranReadingServiceProvider = Provider<QuranReadingService>((ref) {
  final logger = ref.watch(loggerProvider);
  final repository = ref.watch(quranReadingRepositoryProvider);
  return QuranReadingService(repository, logger);
});

final quranLegacyImportServiceProvider = Provider<QuranLegacyImportService>((ref) {
  return QuranLegacyImportService(
    legacyRepository: ref.watch(quranRepositoryProvider),
    readingService: ref.watch(quranReadingServiceProvider),
    logger: ref.watch(loggerProvider),
  );
});

final quranReadingControllerProvider =
    AsyncNotifierProvider<QuranReadingController, List<QuranReading>>(
  QuranReadingController.new,
);

final quranPagesThisWeekProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(quranReadingServiceProvider);
  final now = DateTime.now();
  final startOfWeek = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final result = await service.getByDateRange(startOfWeek, now);
  final logs = result.data ?? <QuranReading>[];
  return logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
});

final quranAllReadingsProvider = FutureProvider<List<QuranReading>>((ref) async {
  final repo = ref.watch(quranReadingRepositoryProvider);
  final result = await repo.getByUserId(demoUserId);
  return result.data ?? <QuranReading>[];
});

/// Pages read per day for the last 7 days, oldest first — feeds a trend chart.
final quranPagesLast7DaysProvider = FutureProvider<List<double>>((ref) async {
  final repo = ref.watch(quranReadingRepositoryProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final result = await repo.getByDateRange(start, now);
  final logs = result.data ?? <QuranReading>[];

  final byDay = <DateTime, int>{};
  for (final log in logs) {
    final day = DateTime(log.readAt.year, log.readAt.month, log.readAt.day);
    byDay[day] = (byDay[day] ?? 0) + log.pagesRead;
  }

  return List<double>.generate(7, (i) {
    final day = start.add(Duration(days: i));
    return (byDay[day] ?? 0).toDouble();
  });
});

class QuranReadingController extends AsyncNotifier<List<QuranReading>> {
  @override
  Future<List<QuranReading>> build() async {
    final service = ref.read(quranReadingServiceProvider);
    final result = await service.getTodayReadings(demoUserId);
    return result.data ?? <QuranReading>[];
  }

  Future<String?> addReading({
    required int surahNumber,
    required int ayahFrom,
    required int ayahTo,
    required int durationMinutes,
    required int pagesRead,
    required bool memorized,
    String? place,
  }) async {
    final service = ref.read(quranReadingServiceProvider);
    final result = await service.logReading(
      userId: demoUserId,
      surahNumber: surahNumber,
      ayahFrom: ayahFrom,
      ayahTo: ayahTo,
      durationMinutes: durationMinutes,
      pagesRead: pagesRead,
      memorized: memorized,
      place: place,
    );

    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    ref.invalidate(quranAllReadingsProvider);
    ref.invalidate(quranPagesLast7DaysProvider);
    ref.invalidate(quranPagesThisWeekProvider);
    return null;
  }

  Future<String?> importLegacyProgress() async {
    final result = await ref.read(quranLegacyImportServiceProvider).importLegacyProgress();
    if (result.isFailure) {
      return result.error!.toString();
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    ref.invalidate(quranAllReadingsProvider);
    ref.invalidate(quranPagesLast7DaysProvider);
    ref.invalidate(quranPagesThisWeekProvider);
    return null;
  }
}
