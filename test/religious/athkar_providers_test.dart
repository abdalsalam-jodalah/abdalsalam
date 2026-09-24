import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/religious/athkar_content.dart';
import 'package:abdalsalam/data/models/religious/athkar_log.dart';
import 'package:abdalsalam/features/religious/providers/athkar_providers.dart';
import 'package:abdalsalam/features/religious/providers/prayer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'religious_fakes.dart';

AthkarContent _content(String id) {
  final now = DateTime(2026, 1, 1);
  return AthkarContent(
    id: id,
    createdAt: now,
    updatedAt: now,
    category: AthkarCategory.morning,
    arabicText: 'ذكر',
    targetCount: 3,
    isBuiltIn: true,
    isCustom: false,
    sortOrder: 0,
  );
}

AthkarLog _log(String id) {
  final now = DateTime(2026, 1, 1);
  return AthkarLog(
    id: id,
    createdAt: now,
    updatedAt: now,
    userId: demoUserId,
    athkarContentId: 'content-1',
    category: AthkarCategory.morning,
    countDone: 3,
    targetCount: 3,
    completedAt: now,
  );
}

void main() {
  group('athkarCategoryProvider', () {
    test('surfaces a failing service as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          athkarServiceProvider.overrideWithValue(
            FakeAthkarService(
              mergedResult: Failure(DatabaseError('seed failed')),
              logCompletionResult: Failure(DatabaseError('unused')),
              addCustomAthkarResult: Failure(DatabaseError('unused')),
              deleteCustomAthkarResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(athkarCategoryProvider(null).future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the merged content on success', () async {
      final content = [_content('1')];
      final container = ProviderContainer(
        overrides: [
          athkarServiceProvider.overrideWithValue(
            FakeAthkarService(
              mergedResult: Success(content),
              logCompletionResult: Failure(DatabaseError('unused')),
              addCustomAthkarResult: Failure(DatabaseError('unused')),
              deleteCustomAthkarResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(athkarCategoryProvider(null).future), content);
    });
  });

  group('AthkarLogsController', () {
    test('build() surfaces a failing repository as AsyncError', () async {
      final container = ProviderContainer(
        overrides: [
          athkarLogRepositoryProvider.overrideWithValue(
            FakeAthkarLogRepository(byUserIdResult: Failure(DatabaseError('read failed'))),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(athkarLogsControllerProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('logCompletion keeps previous data and returns the AppError on failure', () async {
      final existing = [_log('existing')];
      final container = ProviderContainer(
        overrides: [
          athkarLogRepositoryProvider.overrideWithValue(
            FakeAthkarLogRepository(byUserIdResult: Success(existing)),
          ),
          athkarServiceProvider.overrideWithValue(
            FakeAthkarService(
              mergedResult: Failure(DatabaseError('unused')),
              logCompletionResult: Failure(ValidationError('bad count')),
              addCustomAthkarResult: Failure(DatabaseError('unused')),
              deleteCustomAthkarResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(athkarLogsControllerProvider.future);

      final error = await container
          .read(athkarLogsControllerProvider.notifier)
          .logCompletion(content: _content('1'), countDone: 3);

      expect(error, isA<ValidationError>());
      final state = container.read(athkarLogsControllerProvider);
      expect(state, isA<AsyncData<List<AthkarLog>>>());
      expect(state.value, existing);
    });

    test('logCompletion refreshes state and returns null on success', () async {
      final container = ProviderContainer(
        overrides: [
          athkarLogRepositoryProvider.overrideWithValue(
            FakeAthkarLogRepository(byUserIdResult: Success(<AthkarLog>[])),
          ),
          athkarServiceProvider.overrideWithValue(
            FakeAthkarService(
              mergedResult: Failure(DatabaseError('unused')),
              logCompletionResult: Success(_log('new')),
              addCustomAthkarResult: Failure(DatabaseError('unused')),
              deleteCustomAthkarResult: Failure(DatabaseError('unused')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(athkarLogsControllerProvider.future);

      final error = await container
          .read(athkarLogsControllerProvider.notifier)
          .logCompletion(content: _content('1'), countDone: 3);

      expect(error, isNull);
      expect(container.read(athkarLogsControllerProvider), isA<AsyncData<List<AthkarLog>>>());
    });

    test('deleteCustomAthkar returns the AppError on failure', () async {
      final container = ProviderContainer(
        overrides: [
          athkarLogRepositoryProvider.overrideWithValue(
            FakeAthkarLogRepository(byUserIdResult: Success(<AthkarLog>[])),
          ),
          athkarServiceProvider.overrideWithValue(
            FakeAthkarService(
              mergedResult: Failure(DatabaseError('unused')),
              logCompletionResult: Failure(DatabaseError('unused')),
              addCustomAthkarResult: Failure(DatabaseError('unused')),
              deleteCustomAthkarResult: Failure(NotFoundError('missing')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final error = await container
          .read(athkarLogsControllerProvider.notifier)
          .deleteCustomAthkar('missing-id');

      expect(error, isA<NotFoundError>());
    });
  });
}
