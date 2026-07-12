// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/religious/quran_progress.dart';
import '../../../data/models/religious/quran_reading.dart';
import '../../../data/repositories/religious/quran_reading_repository.dart';
import '../../../providers/app_providers.dart';
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
  static const _uuid = Uuid();

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

  /// One-shot manual migration of legacy [QuranProgress] rows into the
  /// richer [QuranReading] model. Surah/ayah range is unknown for legacy
  /// rows and is recorded as 0.
  Future<String?> importLegacyProgress() async {
    final legacyRepo = ref.read(quranRepositoryProvider);
    final legacyResult = await legacyRepo.getAll();
    if (legacyResult.isFailure) {
      return legacyResult.error!.toString();
    }

    final service = ref.read(quranReadingServiceProvider);
    for (final legacy in legacyResult.data!) {
      final now = DateTime.now();
      final entity = QuranReading(
        id: _uuid.v4(),
        createdAt: now,
        updatedAt: now,
        userId: legacy.userId,
        surahNumber: 0,
        ayahFrom: 0,
        ayahTo: 0,
        readAt: legacy.loggedAt,
        durationMinutes: legacy.minutesSpent,
        memorized: false,
        pagesRead: legacy.pagesRead,
        place: null,
      );
      final created = await service.create(entity);
      if (created.isFailure) {
        return created.error!.toString();
      }
    }

    state = const AsyncLoading();
    state = AsyncData(await build());
    ref.invalidate(quranAllReadingsProvider);
    ref.invalidate(quranPagesLast7DaysProvider);
    ref.invalidate(quranPagesThisWeekProvider);
    return null;
  }
}
