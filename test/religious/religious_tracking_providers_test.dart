import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_times_snapshot.dart';
import 'package:abdalsalam/data/models/religious/religious_entry.dart';
import 'package:abdalsalam/features/religious/providers/religious_tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

PrayerTimesSnapshot _snapshot() {
  final now = DateTime(2026, 1, 1);
  return PrayerTimesSnapshot(
    id: 'snap-1',
    createdAt: now,
    updatedAt: now,
    dateKey: '2026-01-01',
    forDate: now,
    fetchedAt: now,
    sourceUrl: 'scraped',
    fajr: now,
    dhuhr: now,
    asr: now,
    maghrib: now,
    isha: now,
  );
}

ReligiousEntry _entry(String id) {
  final now = DateTime(2026, 1, 1);
  return ReligiousEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: religiousDemoUserId,
    type: ReligiousEntryType.prayer,
    loggedAt: now,
    title: 'Fajr',
    count: 1,
  );
}

FakeReligiousTrackerService _service({
  Result<PrayerTimesSnapshot, AppError>? todayPrayerTimesResult,
  Result<Map<String, DateTime>, AppError>? previewSourceResult,
  Result<List<ReligiousEntry>, AppError>? historyResult,
  Result<ReligiousEntry, AppError>? logEntryResult,
  Result<PrayerTimesSnapshot, AppError>? syncResult,
}) {
  return FakeReligiousTrackerService(
    todayPrayerTimesResult: todayPrayerTimesResult ?? Failure(DatabaseError('unused')),
    previewSourceResult: previewSourceResult ?? Failure(DatabaseError('unused')),
    historyResult: historyResult ?? Failure(DatabaseError('unused')),
    logEntryResult: logEntryResult ?? Failure(DatabaseError('unused')),
    syncResult: syncResult ?? Failure(DatabaseError('unused')),
  );
}

void main() {
  group('todayPrayerTimesProvider', () {
    test('surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(todayPrayerTimesResult: Failure(NetworkError('offline'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(todayPrayerTimesProvider.future),
        throwsA(isA<NetworkError>()),
      );
    });

    test('returns the snapshot on success', () async {
      final snapshot = _snapshot();
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(todayPrayerTimesResult: Success(snapshot)),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(todayPrayerTimesProvider.future), snapshot);
    });
  });

  group('prayerTimeSourcePreviewProvider', () {
    test('surfaces a failing preview as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(previewSourceResult: Failure(ValidationError('bad source'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(prayerTimeSourcePreviewProvider('adhan').future),
        throwsA(isA<ValidationError>()),
      );
    });
  });

  group('ReligiousLogsController', () {
    test('build() surfaces a failing history read as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(historyResult: Failure(DatabaseError('read failed'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(religiousLogsControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('addEntry keeps previous data and returns the AppError on failure', () async {
      final existing = [_entry('existing')];
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(
              historyResult: Success(existing),
              logEntryResult: Failure(ValidationError('bad title')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(religiousLogsControllerProvider.future);

      final error = await container.read(religiousLogsControllerProvider.notifier).addEntry(
            type: ReligiousEntryType.prayer,
            title: 'Fajr',
            count: 1,
          );

      expect(error, isA<ValidationError>());
      final state = container.read(religiousLogsControllerProvider);
      expect(state, isA<AsyncData<List<ReligiousEntry>>>());
      expect(state.value, existing);
    });

    test('addEntry refreshes state and returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(
              historyResult: Success(<ReligiousEntry>[]),
              logEntryResult: Success(_entry('new')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(religiousLogsControllerProvider.future);

      final error = await container.read(religiousLogsControllerProvider.notifier).addEntry(
            type: ReligiousEntryType.prayer,
            title: 'Fajr',
            count: 1,
          );

      expect(error, isNull);
      expect(container.read(religiousLogsControllerProvider), isA<AsyncData<List<ReligiousEntry>>>());
    });

    test('syncPrayerTimes returns the AppError on failure', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(
              historyResult: Success(<ReligiousEntry>[]),
              syncResult: Failure(NetworkError('offline')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final error =
          await container.read(religiousLogsControllerProvider.notifier).syncPrayerTimes();

      expect(error, isA<NetworkError>());
    });

    test('syncPrayerTimes returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          religiousTrackerServiceProvider.overrideWithValue(
            _service(
              historyResult: Success(<ReligiousEntry>[]),
              syncResult: Success(_snapshot()),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final error =
          await container.read(religiousLogsControllerProvider.notifier).syncPrayerTimes();

      expect(error, isNull);
    });
  });
}
