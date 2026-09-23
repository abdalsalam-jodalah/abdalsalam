import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import '../../../data/models/health/blood_test.dart';
import '../../../data/models/health/doctor_visit.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../data/models/health/medication.dart';
import '../../../data/repositories/health/blood_test_repository.dart';
import '../../../data/repositories/health/doctor_visit_repository.dart';
import '../../../data/repositories/health/health_metric_repository.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/health/medication_log_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../food/providers/food_providers.dart';
import '../../sleep/providers/sleep_providers.dart';
import '../services/blood_test_service.dart';
import '../services/doctor_visit_service.dart';
import '../services/health_metric_service.dart';
import '../services/health_report_service.dart';
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

final healthMetricRepositoryProvider = Provider<HealthMetricRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'HealthMetricRepository',
    moduleType: logic.ModuleType.repository,
  );
  return HealthMetricRepositoryImpl(storage, logger);
});

final healthMetricServiceProvider = Provider<HealthMetricService>((ref) {
  return HealthMetricService(
    ref.watch(healthMetricRepositoryProvider),
    LoggerService.forModule(
      'HealthMetricService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final healthMetricsProvider = FutureProvider<List<HealthMetric>>((ref) async {
  final service = ref.watch(healthMetricServiceProvider);
  final result = await service.getActive();
  final metrics = result.data ?? [];
  metrics.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  return metrics;
});

final healthMetricStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(healthMetricServiceProvider);
  final result = await service.getStatistics();
  return result.data ?? {};
});

final bloodTestRepositoryProvider = Provider<BloodTestRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'BloodTestRepository',
    moduleType: logic.ModuleType.repository,
  );
  return BloodTestRepositoryImpl(storage, logger);
});

final bloodTestServiceProvider = Provider<BloodTestService>((ref) {
  return BloodTestService(
    ref.watch(bloodTestRepositoryProvider),
    LoggerService.forModule(
      'BloodTestService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final bloodTestsProvider = FutureProvider<List<BloodTest>>((ref) async {
  final service = ref.watch(bloodTestServiceProvider);
  final result = await service.getActive();
  final tests = result.data ?? [];
  tests.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
  return tests;
});

final bloodTestStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(bloodTestServiceProvider);
  final result = await service.getStatistics();
  return result.data ?? {};
});

final doctorVisitRepositoryProvider = Provider<DoctorVisitRepository>((ref) {
  final storage = ref.watch(storageGatewayProvider);
  final logger = LoggerService.forModule(
    'DoctorVisitRepository',
    moduleType: logic.ModuleType.repository,
  );
  return DoctorVisitRepositoryImpl(storage, logger);
});

final doctorVisitServiceProvider = Provider<DoctorVisitService>((ref) {
  return DoctorVisitService(
    ref.watch(doctorVisitRepositoryProvider),
    LoggerService.forModule(
      'DoctorVisitService',
      moduleType: logic.ModuleType.service,
    ),
    attachments: ref.watch(attachmentStorageServiceProvider),
  );
});

final doctorVisitsProvider = FutureProvider<List<DoctorVisit>>((ref) async {
  final service = ref.watch(doctorVisitServiceProvider);
  final result = await service.getActive();
  final visits = result.data ?? [];
  visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
  return visits;
});

final doctorVisitStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(doctorVisitServiceProvider);
  final result = await service.getStatistics();
  return result.data ?? {};
});

final healthReportServiceProvider = Provider<HealthReportService>((ref) {
  return HealthReportService(
    medicationService: ref.watch(medicationServiceProvider),
    healthMetricService: ref.watch(healthMetricServiceProvider),
    bloodTestService: ref.watch(bloodTestServiceProvider),
    doctorVisitService: ref.watch(doctorVisitServiceProvider),
    logger: LoggerService.forModule(
      'HealthReportService',
      moduleType: logic.ModuleType.service,
    ),
  );
});

final todayMedicationChecklistProvider = FutureProvider<List<DailyMedicationCheck>>((ref) async {
  final service = ref.watch(medicationServiceProvider);
  final result = await service.getDailyChecklist(DateTime.now());
  return result.data ?? [];
});

class HealthActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime date;

  const HealthActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

final healthActivityFeedProvider = FutureProvider<List<HealthActivityItem>>((ref) async {
  final metrics = await ref.watch(healthMetricsProvider.future);
  final bloodTests = await ref.watch(bloodTestsProvider.future);
  final visits = await ref.watch(doctorVisitsProvider.future);

  final items = <HealthActivityItem>[
    for (final metric in metrics)
      HealthActivityItem(
        icon: Icons.monitor_heart_outlined,
        title: '${metric.metricType}: ${metric.value} ${metric.unit}',
        subtitle: 'Metric logged',
        date: metric.measuredAt,
      ),
    for (final test in bloodTests)
      HealthActivityItem(
        icon: Icons.science_outlined,
        title: test.testType,
        subtitle: test.completedDate != null ? 'Blood test completed' : 'Blood test scheduled',
        date: test.completedDate ?? test.scheduledDate,
      ),
    for (final visit in visits)
      HealthActivityItem(
        icon: Icons.medical_services_outlined,
        title: visit.doctorName,
        subtitle: visit.reason,
        date: visit.visitDate,
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  return items.take(10).toList(growable: false);
});

final healthSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final sleepStats = await ref.watch(sleepLogStatisticsProvider.future);
  final foodStats = await ref.watch(foodLogStatisticsProvider.future);

  return <String, dynamic>{
    'sleepAverageDurationMinutesLast7Days': sleepStats['averageDurationMinutesLast7Days'],
    'sleepAverageFeelingOnWakeup': sleepStats['averageFeelingOnWakeup'],
    'foodTodayCalories': foodStats['todayCalories'],
    'foodTodayProteinGrams': foodStats['todayProteinGrams'],
    'foodTodayFatGrams': foodStats['todayFatGrams'],
    'foodTodayCarbGrams': foodStats['todayCarbGrams'],
  };
});
