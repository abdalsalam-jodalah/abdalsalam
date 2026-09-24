import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/sleep/sleep_log.dart';
import '../../../data/repositories/sleep/sleep_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/sleep_log_service.dart';

final sleepLogRepositoryProvider = Provider<SleepLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'SleepLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return SleepLogRepositoryImpl(storage, logger);
});

final sleepLogServiceProvider = Provider<SleepLogService>((ref) {
  return SleepLogService(
    ref.watch(sleepLogRepositoryProvider),
    LoggerService.forModule(
      'SleepLogService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) async {
  final service = ref.watch(sleepLogServiceProvider);
  final result = await service.getActive();
  final logs = result.getOrThrow();
  logs.sort((a, b) => b.sleepStart.compareTo(a.sleepStart));
  return logs;
});

final sleepLogStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(sleepLogServiceProvider);
  final result = await service.getStatistics();
  return result.getOrThrow();
});

final sleepInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(sleepLogServiceProvider);
  final result = await service.getInsights();
  return result.getOrThrow();
});

final sleepGoalHoursProvider = FutureProvider<double>((ref) async {
  final settings = await ref.watch(settingsServiceProvider).getSettings();
  return (settings['sleepGoalHours'] as num?)?.toDouble() ?? 8.0;
});
