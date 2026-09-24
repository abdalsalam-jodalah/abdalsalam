import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:abdalsalam/data/repositories/sleep/sleep_log_repository.dart';
import 'package:abdalsalam/features/sleep/providers/sleep_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSleepLogRepository implements SleepLogRepository {
  final List<SleepLog> items;
  bool shouldFailGetActive = false;

  FakeSleepLogRepository([List<SleepLog>? seed]) : items = seed ?? <SleepLog>[];

  @override
  Future<Result<List<SleepLog>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<SleepLog>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  setUpAll(() async {
    await LoggerService.initialize();
  });

  ProviderContainer buildContainer(SleepLogRepository repository) {
    return ProviderContainer(
      overrides: [sleepLogRepositoryProvider.overrideWithValue(repository)],
    );
  }

  group('sleepLogsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final container = buildContainer(FakeSleepLogRepository()..shouldFailGetActive = true);
      addTearDown(container.dispose);

      await expectLater(
        container.read(sleepLogsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no logs', () async {
      final container = buildContainer(FakeSleepLogRepository());
      addTearDown(container.dispose);

      final result = await container.read(sleepLogsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('sleepLogStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final container = buildContainer(FakeSleepLogRepository()..shouldFailGetActive = true);
      addTearDown(container.dispose);

      await expectLater(
        container.read(sleepLogStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer(FakeSleepLogRepository());
      addTearDown(container.dispose);

      final result = await container.read(sleepLogStatisticsProvider.future);
      expect(result['totalLogs'], 0);
    });
  });

  group('sleepInsightsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final container = buildContainer(FakeSleepLogRepository()..shouldFailGetActive = true);
      addTearDown(container.dispose);

      await expectLater(
        container.read(sleepInsightsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real insights on success', () async {
      final container = buildContainer(FakeSleepLogRepository());
      addTearDown(container.dispose);

      final result = await container.read(sleepInsightsProvider.future);
      expect(result['caffeineTooCloseNights'], 0);
    });
  });
}
