import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/quran_reading.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_reading_providers.dart';
import 'package:abdalsalam/features/religious/services/quran_legacy_import_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

QuranReading _reading(String id) {
  final now = DateTime(2026, 1, 1);
  return QuranReading(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    surahNumber: 1,
    ayahFrom: 1,
    ayahTo: 7,
    readAt: now,
    durationMinutes: 10,
    memorized: false,
    pagesRead: 1,
  );
}

void main() {
  group('quranAllReadingsProvider', () {
    test('surfaces a failing repository as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          quranReadingRepositoryProvider.overrideWithValue(
            FakeQuranReadingRepository(
              byUserIdResult: Failure(DatabaseError('boom')),
              byDateRangeResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quranAllReadingsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the readings on success', () async {
      final readings = [_reading('1')];
      final container = ProviderContainer(
        overrides: [
          quranReadingRepositoryProvider.overrideWithValue(
            FakeQuranReadingRepository(
              byUserIdResult: Success(readings),
              byDateRangeResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(quranAllReadingsProvider.future), readings);
    });
  });

  group('quranPagesThisWeekProvider', () {
    test('surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Failure(DatabaseError('unused')),
              logReadingResult: Failure(DatabaseError('unused')),
              byDateRangeResult: Failure(DatabaseError('range failed')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quranPagesThisWeekProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });
  });

  group('QuranReadingController', () {
    test('build() surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Failure(DatabaseError('read failed')),
              logReadingResult: Failure(DatabaseError('unused')),
              byDateRangeResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quranReadingControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('addReading keeps previous data and returns the AppError on failure', () async {
      final existing = [_reading('existing')];
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Success(existing),
              logReadingResult: Failure(ValidationError('bad surah')),
              byDateRangeResult: Success(existing),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranReadingControllerProvider.future);

      final error = await container.read(quranReadingControllerProvider.notifier).addReading(
            surahNumber: 1,
            ayahFrom: 1,
            ayahTo: 7,
            durationMinutes: 10,
            pagesRead: 1,
            memorized: false,
          );

      expect(error, isA<ValidationError>());
      final state = container.read(quranReadingControllerProvider);
      expect(state, isA<AsyncData<List<QuranReading>>>());
      expect(state.value, existing);
    });

    test('addReading refreshes state and returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Success(<QuranReading>[]),
              logReadingResult: Success(_reading('new')),
              byDateRangeResult: Success(<QuranReading>[]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranReadingControllerProvider.future);

      final error = await container.read(quranReadingControllerProvider.notifier).addReading(
            surahNumber: 1,
            ayahFrom: 1,
            ayahTo: 7,
            durationMinutes: 10,
            pagesRead: 1,
            memorized: false,
          );

      expect(error, isNull);
      expect(container.read(quranReadingControllerProvider), isA<AsyncData<List<QuranReading>>>());
    });

    test('importLegacyProgress returns the report and refreshes state on success', () async {
      const report = QuranLegacyImportReport(
        importedCount: 2,
        alreadyImportedCount: 1,
        skippedLegacyIds: ['skipped-1'],
      );
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Success(<QuranReading>[]),
              logReadingResult: Failure(DatabaseError('unused')),
              byDateRangeResult: Success(<QuranReading>[]),
            ),
          ),
          quranLegacyImportServiceProvider.overrideWithValue(
            FakeQuranLegacyImportService(importResult: const Success(report)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranReadingControllerProvider.future);

      final result =
          await container.read(quranReadingControllerProvider.notifier).importLegacyProgress();

      expect(result.isSuccess, isTrue);
      expect(result.data, report);
      expect(container.read(quranReadingControllerProvider), isA<AsyncData<List<QuranReading>>>());
    });

    test('importLegacyProgress returns the AppError without touching state on failure', () async {
      final container = ProviderContainer(
        overrides: [
          quranReadingServiceProvider.overrideWithValue(
            FakeQuranReadingService(
              todayReadingsResult: Success(<QuranReading>[]),
              logReadingResult: Failure(DatabaseError('unused')),
              byDateRangeResult: Success(<QuranReading>[]),
            ),
          ),
          quranLegacyImportServiceProvider.overrideWithValue(
            FakeQuranLegacyImportService(importResult: Failure(DatabaseError('legacy read failed'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranReadingControllerProvider.future);

      final result =
          await container.read(quranReadingControllerProvider.notifier).importLegacyProgress();

      expect(result.isFailure, isTrue);
      expect(result.error, isA<DatabaseError>());
      expect(container.read(quranReadingControllerProvider), isA<AsyncData<List<QuranReading>>>());
    });
  });
}
