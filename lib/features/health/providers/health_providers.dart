import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/health/medication.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/health/medication_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/health_service.dart';
import '../services/medication_service.dart';

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'HealthRepository',
    moduleType: logic.ModuleType.repository,
  );
  return HealthRepositoryImpl(storage, logger);
});

final medicationLogRepositoryProvider = Provider<MedicationLogRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'MedicationLogRepository',
    moduleType: logic.ModuleType.repository,
  );
  return MedicationLogRepositoryImpl(storage, logger);
});

final medicationServiceProvider = Provider<MedicationService>((ref) {
  return MedicationService(
    repository: ref.watch(healthRepositoryProvider),
    logger: LoggerService.forModule(
      'MedicationService',
      moduleType: logic.ModuleType.service,
    ),
    logRepository: ref.watch(medicationLogRepositoryProvider),
  );
});

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(
    ref.watch(healthRepositoryProvider),
    LoggerService.forModule(
      'HealthService',
      moduleType: logic.ModuleType.service,
    ),
    reminders: ref.watch(reminderServiceProvider),
  );
});

final sortedMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final service = ref.watch(medicationServiceProvider);
  final result = await service.getMedicationsSorted();
  return result.data ?? [];
});

final medicationStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(medicationServiceProvider);
  final result = await service.getStatistics();
  return result.data ?? {};
});
