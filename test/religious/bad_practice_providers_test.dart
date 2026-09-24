import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/bad_practice_log.dart';
import 'package:abdalsalam/features/religious/providers/bad_practice_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

BadPracticeLog _log(String id) {
  final now = DateTime(2026, 1, 1);
  return BadPracticeLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    title: 'Slept in',
    occurredAt: now,
  );
}

void main() {
  group('BadPracticeLogController', () {
    test('build() surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          badPracticeServiceProvider.overrideWithValue(
            FakeBadPracticeService(
              historyResult: Failure(DatabaseError('read failed')),
              logEventResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(badPracticeLogControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('logEvent keeps previous data and returns the AppError on failure', () async {
      final existing = [_log('existing')];
      final container = ProviderContainer(
        overrides: [
          badPracticeServiceProvider.overrideWithValue(
            FakeBadPracticeService(
              historyResult: Success(existing),
              logEventResult: Failure(ValidationError('bad title')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(badPracticeLogControllerProvider.future);

      final error = await container.read(badPracticeLogControllerProvider.notifier).logEvent(
            title: 'Overslept',
            occurredAt: DateTime(2026, 1, 2),
          );

      expect(error, isA<ValidationError>());
      final state = container.read(badPracticeLogControllerProvider);
      expect(state, isA<AsyncData<List<BadPracticeLog>>>());
      expect(state.value, existing);
    });

    test('logEvent refreshes state and returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          badPracticeServiceProvider.overrideWithValue(
            FakeBadPracticeService(
              historyResult: Success(<BadPracticeLog>[]),
              logEventResult: Success(_log('new')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(badPracticeLogControllerProvider.future);

      final error = await container.read(badPracticeLogControllerProvider.notifier).logEvent(
            title: 'Overslept',
            occurredAt: DateTime(2026, 1, 2),
          );

      expect(error, isNull);
      expect(container.read(badPracticeLogControllerProvider), isA<AsyncData<List<BadPracticeLog>>>());
    });
  });
}
