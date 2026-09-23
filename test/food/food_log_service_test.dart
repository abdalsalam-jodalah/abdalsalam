import 'package:abdalsalam/data/models/food/food_log.dart';
import 'package:abdalsalam/data/repositories/food/food_log_repository.dart';
import 'package:abdalsalam/features/food/services/food_log_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/database_schema_initializer.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const uuid = Uuid();

  FoodLog buildLog({
    String? category,
    String? dishName,
    DateTime? loggedAt,
    double? calories,
    double? proteinGrams,
    double? fatGrams,
    double? carbGrams,
  }) {
    return FoodLog(
      id: uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'u1',
      category: category ?? 'Lunch',
      dishName: dishName ?? 'Chicken rice',
      quantity: '1 bowl',
      loggedAt: loggedAt ?? DateTime.now(),
      calories: calories,
      proteinGrams: proteinGrams,
      fatGrams: fatGrams,
      carbGrams: carbGrams,
    );
  }

  group('FoodLogService', () {
    late FoodLogService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LoggerService.initialize();
      await StorageGateway.instance.initialize(databaseName: 'test_food_log_service_test.db');
      await DatabaseSchemaInitializer.initialize(StorageGateway.instance);
      await StorageGateway.instance.clearTable('food_logs');
      final logger = LoggerService.forModule('FoodLogServiceTest');
      final FoodLogRepository repository = FoodLogRepositoryImpl(StorageGateway.instance, logger);
      service = FoodLogService(repository, logger);
    });

    test('validate succeeds for a well-formed log', () {
      final result = service.validate(buildLog());
      expect(result.isSuccess, isTrue);
    });

    test('validate fails when dishName is empty', () {
      final result = service.validate(buildLog(dishName: ''));
      expect(result.isFailure, isTrue);
    });

    test('validate fails when category is empty', () {
      final result = service.validate(buildLog(category: ''));
      expect(result.isFailure, isTrue);
    });

    test('create rejects an invalid log before hitting storage', () async {
      final result = await service.create(buildLog(dishName: ''));
      expect(result.isFailure, isTrue);
    });

    test('getStatistics sums today\'s nutrition and counts meals by category', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await service.create(buildLog(
        category: 'Breakfast',
        loggedAt: now,
        calories: 300,
        proteinGrams: 20,
        fatGrams: 10,
        carbGrams: 30,
      ));
      await service.create(buildLog(
        category: 'Lunch',
        loggedAt: now,
        calories: 500,
        proteinGrams: 30,
        fatGrams: 15,
        carbGrams: 60,
      ));
      await service.create(buildLog(
        category: 'Dinner',
        loggedAt: yesterday,
        calories: 999,
      ));

      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 3);
      expect(stats.data?['todayCalories'], 800.0);
      expect(stats.data?['todayProteinGrams'], 50.0);
      expect(stats.data?['todayFatGrams'], 25.0);
      expect(stats.data?['todayCarbGrams'], 90.0);
      expect(stats.data?['todayMealCountByCategory'], {'Breakfast': 1, 'Lunch': 1});
    });

    test('getStatistics returns zero totals when there are no logs', () async {
      final stats = await service.getStatistics();
      expect(stats.isSuccess, isTrue);
      expect(stats.data?['totalLogs'], 0);
      expect(stats.data?['todayCalories'], 0.0);
      expect(stats.data?['todayMealCountByCategory'], <String, int>{});
    });
  });
}
