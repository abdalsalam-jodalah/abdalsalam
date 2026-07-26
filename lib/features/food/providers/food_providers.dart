import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/food/food_log.dart';
import '../../../data/repositories/food/food_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/food_log_service.dart';

final foodLogRepositoryProvider = Provider<FoodLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'FoodLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return FoodLogRepositoryImpl(storage, logger);
});

final foodLogServiceProvider = Provider<FoodLogService>((ref) {
  return FoodLogService(
    ref.watch(foodLogRepositoryProvider),
    LoggerService.forModule(
      'FoodLogService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final foodLogsProvider = FutureProvider<List<FoodLog>>((ref) async {
  final service = ref.watch(foodLogServiceProvider);
  final result = await service.getActive();
  final logs = result.data ?? [];
  logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  return logs;
});

final foodLogStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(foodLogServiceProvider);
  final result = await service.getStatistics();
  return result.data ?? {};
});
