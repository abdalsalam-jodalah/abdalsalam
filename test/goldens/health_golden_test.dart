import 'package:abdalsalam/core/theme/appearance.dart';
import 'package:abdalsalam/data/models/health/health_metric.dart';
import 'package:abdalsalam/data/models/sleep/sleep_log.dart';
import 'package:abdalsalam/features/health/providers/health_providers.dart';
import 'package:abdalsalam/features/health/screens/health_home_screen.dart';
import 'package:abdalsalam/features/health/screens/medication_list_screen.dart';
import 'package:abdalsalam/features/health/services/medication_service.dart';
import 'package:abdalsalam/features/sleep/providers/sleep_providers.dart';
import 'package:abdalsalam/features/sleep/screens/sleep_home_screen.dart';
import 'package:abdalsalam/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../health/health_fakes.dart';
import 'support/golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  final measuredAt = DateTime(2026, 9, 24, 8, 0);

  final healthOverrides = <Override>[
    medicationStatisticsProvider.overrideWith((ref) async => <String, dynamic>{
          'adherenceRate': 82.0,
          'todayTaken': 2,
          'todayTotal': 3,
          'todayPending': 1,
          'activeMedications': 3,
        }),
    todayMedicationChecklistProvider.overrideWith((ref) async => <DailyMedicationCheck>[
          DailyMedicationCheck(
            log: buildMedicationLog(scheduledFor: measuredAt),
            medication: buildMedication(),
          ),
        ]),
    healthMetricsProvider.overrideWith((ref) async => <HealthMetric>[
          HealthMetric(
            id: 'metric-1',
            createdAt: measuredAt,
            updatedAt: measuredAt,
            userId: 'user',
            metricType: 'Weight',
            value: 72,
            unit: 'kg',
            measuredAt: measuredAt,
            notes: null,
          ),
        ]),
    bloodTestStatisticsProvider.overrideWith((ref) async => <String, dynamic>{
          'nextTestDate': measuredAt.toIso8601String(),
          'scheduledCount': 1,
          'completedCount': 2,
        }),
    doctorVisitStatisticsProvider.overrideWith((ref) async => <String, dynamic>{
          'nextVisitDate': measuredAt.toIso8601String(),
          'totalVisits': 4,
        }),
    healthActivityFeedProvider.overrideWith((ref) async => <HealthActivityItem>[
          HealthActivityItem(
            icon: Icons.monitor_heart_outlined,
            title: 'Weight: 72 kg',
            subtitle: 'Metric logged',
            date: measuredAt,
          ),
        ]),
    healthSummaryProvider.overrideWith((ref) async => <String, dynamic>{
          'sleepAverageDurationMinutesLast7Days': 420.0,
          'sleepAverageFeelingOnWakeup': 4.0,
          'foodTodayCalories': 1800,
          'foodTodayProteinGrams': 90,
          'foodTodayFatGrams': 60,
          'foodTodayCarbGrams': 200,
        }),
  ];

  final medicationListOverrides = <Override>[
    healthRepositoryProvider.overrideWithValue(FakeHealthRepository([buildMedication()])),
    medicationLogRepositoryProvider.overrideWithValue(
      FakeMedicationLogRepository([buildMedicationLog(scheduledFor: DateTime.now())]),
    ),
    reminderServiceProvider.overrideWithValue(FakeReminderService()),
  ];

  final sleepOverrides = <Override>[
    sleepLogsProvider.overrideWith((ref) async => <SleepLog>[
          SleepLog(
            id: 'log-1',
            createdAt: measuredAt,
            updatedAt: measuredAt,
            userId: 'user',
            sleepStart: DateTime(2026, 9, 23, 23, 0),
            sleepEnd: DateTime(2026, 9, 24, 7, 0),
            nightWakeCount: 1,
          ),
        ]),
    sleepLogStatisticsProvider.overrideWith((ref) async => <String, dynamic>{
          'averageFeelingBeforeSleep': 3.5,
          'averageFeelingOnWakeup': 4.0,
          'averageFeelingDuringDay': 4.2,
        }),
    sleepInsightsProvider.overrideWith((ref) async => <String, dynamic>{
          'avgHoursThisWeek': 7.5,
          'weeklyDeltaHours': 0.5,
          'caffeineTooCloseNights': 1,
        }),
    sleepGoalHoursProvider.overrideWith((ref) async => 8.0),
  ];

  for (final brightness in Brightness.values) {
    testWidgets('health home ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1450));
      await tester.pumpWidget(ProviderScope(
        overrides: healthOverrides,
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const HealthHomeScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/health_home_${brightness.name}.png'));
    });

    testWidgets('medication list ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 800));
      await tester.pumpWidget(ProviderScope(
        overrides: medicationListOverrides,
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const MedicationListScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/medication_list_${brightness.name}.png'));
    });

    testWidgets('sleep home ${brightness.name}', (tester) async {
      await setGoldenSurface(tester, const Size(430, 1100));
      await tester.pumpWidget(ProviderScope(
        overrides: sleepOverrides,
        child: goldenHost(
          appearance: Appearance.defaults,
          brightness: brightness,
          child: const SleepHomeScreen(),
        ),
      ));
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('images/sleep_home_${brightness.name}.png'));
    });
  }
}
