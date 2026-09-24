import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/food/food_log.dart';
import 'package:abdalsalam/data/repositories/food/food_log_repository.dart';
import 'package:abdalsalam/features/food/providers/food_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFoodLogRepository implements FoodLogRepository {
  final List<FoodLog> items;
  bool shouldFailGetActive = false;

  FakeFoodLogRepository([List<FoodLog>? seed]) : items = seed ?? <FoodLog>[];

  @override
  Future<Result<List<FoodLog>, AppError>> getActive() async {
    if (shouldFailGetActive) {
      return Failure(DatabaseError('fake storage failure'));
    }
    return Success(List<FoodLog>.of(items));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  setUpAll(() async {
    await LoggerService.initialize();
  });

  ProviderContainer buildContainer(FoodLogRepository repository) {
    return ProviderContainer(
      overrides: [foodLogRepositoryProvider.overrideWithValue(repository)],
    );
  }

  group('foodLogsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final container = buildContainer(FakeFoodLogRepository()..shouldFailGetActive = true);
      addTearDown(container.dispose);

      await expectLater(
        container.read(foodLogsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no logs', () async {
      final container = buildContainer(FakeFoodLogRepository());
      addTearDown(container.dispose);

      final result = await container.read(foodLogsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('foodLogStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final container = buildContainer(FakeFoodLogRepository()..shouldFailGetActive = true);
      addTearDown(container.dispose);

      await expectLater(
        container.read(foodLogStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer(FakeFoodLogRepository());
      addTearDown(container.dispose);

      final result = await container.read(foodLogStatisticsProvider.future);
      expect(result['totalLogs'], 0);
      expect(result['todayCalories'], 0.0);
    });
  });
}
