import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/prayer_log.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/religious_tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

PrayerLog _prayerLog(String id) {
  final now = DateTime(2026, 1, 1, 5);
  return PrayerLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    prayerName: PrayerName.fajr,
    prayedAt: now,
    onTime: true,
  );
}

void main() {
  group('prayerAllLogsProvider', () {
    test('surfaces a failing repository as AsyncError instead of an empty list', () async {
      final container = ProviderContainer(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(
            FakePrayerRepository(byUserIdResult: Failure(DatabaseError('boom'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(prayerAllLogsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the logs on success', () async {
      final logs = [_prayerLog('1')];
      final container = ProviderContainer(
        overrides: [
          prayerRepositoryProvider.overrideWithValue(
            FakePrayerRepository(byUserIdResult: Success(logs)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(prayerAllLogsProvider.future);
      expect(result, logs);
    });
  });

  group('religiousStreakProvider', () {
    test('surfaces a failing statistics call as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          religiousServiceProvider.overrideWithValue(
            FakeReligiousService(statisticsResult: Failure(ServiceError('stats down'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(religiousStreakProvider.future),
        throwsA(isA<ServiceError>()),
      );
    });

    test('returns the current streak on success', () async {
      final container = ProviderContainer(
        overrides: [
          religiousServiceProvider.overrideWithValue(
            FakeReligiousService(
              statisticsResult: Success(<String, dynamic>{'currentStreak': 7}),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(religiousStreakProvider.future), 7);
    });
  });

  group('PrayerLogsController', () {
    test('build() surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          prayerServiceProvider.overrideWithValue(
            FakePrayerService(
              todayLogsResult: Failure(DatabaseError('read failed')),
              logPrayerResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(prayerLogsControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('addPrayer keeps previous data and returns the AppError on failure', () async {
      final existing = [_prayerLog('existing')];
      final container = ProviderContainer(
        overrides: [
          prayerServiceProvider.overrideWithValue(
            FakePrayerService(
              todayLogsResult: Success(existing),
              logPrayerResult: Failure(ValidationError('bad input')),
            ),
          ),
          todayPrayerTimesProvider.overrideWith((ref) => Future.error(DatabaseError('no snapshot'))),
        ],
      );
      addTearDown(container.dispose);

      await container.read(prayerLogsControllerProvider.future);

      final error = await container
          .read(prayerLogsControllerProvider.notifier)
          .addPrayer(prayer: PrayerName.dhuhr);

      expect(error, isA<ValidationError>());
      final state = container.read(prayerLogsControllerProvider);
      expect(state, isA<AsyncData<List<PrayerLog>>>());
      expect(state.value, existing);
    });

    test('addPrayer refreshes state and returns null on success', () async {
      final existing = <PrayerLog>[];
      final added = _prayerLog('new');
      final container = ProviderContainer(
        overrides: [
          prayerServiceProvider.overrideWithValue(
            FakePrayerService(
              todayLogsResult: Success(existing),
              logPrayerResult: Success(added),
            ),
          ),
          todayPrayerTimesProvider.overrideWith((ref) => Future.error(DatabaseError('no snapshot'))),
        ],
      );
      addTearDown(container.dispose);

      await container.read(prayerLogsControllerProvider.future);

      final error = await container
          .read(prayerLogsControllerProvider.notifier)
          .addPrayer(prayer: PrayerName.dhuhr);

      expect(error, isNull);
      final state = container.read(prayerLogsControllerProvider);
      expect(state, isA<AsyncData<List<PrayerLog>>>());
    });
  });
}
