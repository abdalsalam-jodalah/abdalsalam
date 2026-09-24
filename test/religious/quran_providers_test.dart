import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/quran_progress.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:abdalsalam/features/religious/providers/quran_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

// ignore: deprecated_member_use_from_same_package
QuranProgress _progress(String id) {
  final now = DateTime(2026, 1, 1);
  // ignore: deprecated_member_use_from_same_package
  return QuranProgress(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    pagesRead: 3,
    minutesSpent: 15,
    loggedAt: now,
  );
}

void main() {
  group('QuranProgressController', () {
    test('build() surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          quranServiceProvider.overrideWithValue(
            FakeQuranService(
              todayProgressResult: Failure(DatabaseError('read failed')),
              logProgressResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(quranProgressControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('addProgress keeps previous data and returns the AppError on failure', () async {
      final existing = [_progress('existing')];
      final container = ProviderContainer(
        overrides: [
          quranServiceProvider.overrideWithValue(
            FakeQuranService(
              todayProgressResult: Success(existing),
              logProgressResult: Failure(ValidationError('bad pages')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranProgressControllerProvider.future);

      final error = await container
          .read(quranProgressControllerProvider.notifier)
          .addProgress(pagesRead: 2, minutesSpent: 5);

      expect(error, isA<ValidationError>());
      final state = container.read(quranProgressControllerProvider);
      expect(state, isA<AsyncData<List<QuranProgress>>>());
      expect(state.value, existing);
    });

    test('addProgress refreshes state and returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          quranServiceProvider.overrideWithValue(
            FakeQuranService(
              todayProgressResult: Success(<QuranProgress>[]),
              logProgressResult: Success(_progress('new')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(quranProgressControllerProvider.future);

      final error = await container
          .read(quranProgressControllerProvider.notifier)
          .addProgress(pagesRead: 2, minutesSpent: 5);

      expect(error, isNull);
      expect(container.read(quranProgressControllerProvider), isA<AsyncData<List<QuranProgress>>>());
    });
  });
}
