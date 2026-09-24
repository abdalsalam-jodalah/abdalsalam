import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/health/providers/health_providers.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'health_fakes.dart';

void main() {
  setUpAll(() async {
    await LoggerService.initialize();
  });

  ProviderContainer buildContainer({
    FakeHealthRepository? healthRepository,
    FakeMedicationLogRepository? medicationLogRepository,
    FakeHealthMetricRepository? healthMetricRepository,
    FakeBloodTestRepository? bloodTestRepository,
    FakeDoctorVisitRepository? doctorVisitRepository,
  }) {
    final container = ProviderContainer(
      overrides: [
        healthRepositoryProvider.overrideWithValue(healthRepository ?? FakeHealthRepository()),
        medicationLogRepositoryProvider.overrideWithValue(
          medicationLogRepository ?? FakeMedicationLogRepository(),
        ),
        healthMetricRepositoryProvider.overrideWithValue(
          healthMetricRepository ?? FakeHealthMetricRepository(),
        ),
        bloodTestRepositoryProvider.overrideWithValue(bloodTestRepository ?? FakeBloodTestRepository()),
        doctorVisitRepositoryProvider.overrideWithValue(
          doctorVisitRepository ?? FakeDoctorVisitRepository(),
        ),
      ],
    );
    return container;
  }

  group('sortedMedicationsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final repo = FakeHealthRepository()..shouldFailGetActive = true;
      final container = buildContainer(healthRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(sortedMedicationsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns the sorted medications on success', () async {
      final medication = buildMedication();
      final container = buildContainer(healthRepository: FakeHealthRepository([medication]));
      addTearDown(container.dispose);

      final result = await container.read(sortedMedicationsProvider.future);
      expect(result, [medication]);
    });
  });

  group('medicationStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final repo = FakeHealthRepository()..shouldFailGetActive = true;
      final container = buildContainer(healthRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(medicationStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(medicationStatisticsProvider.future);
      expect(result['activeMedications'], 0);
      expect(result['todayTotal'], 0);
    });
  });

  group('todayMedicationChecklistProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final repo = FakeMedicationLogRepository()..shouldFailLookup = true;
      final container = buildContainer(medicationLogRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(todayMedicationChecklistProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty checklist on success when there are no logs', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(todayMedicationChecklistProvider.future);
      expect(result, isEmpty);
    });
  });

  group('healthMetricsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final repo = FakeHealthMetricRepository()..shouldFailGetActive = true;
      final container = buildContainer(healthMetricRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(healthMetricsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no metrics', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(healthMetricsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('healthMetricStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final repo = FakeHealthMetricRepository()..shouldFailGetActive = true;
      final container = buildContainer(healthMetricRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(healthMetricStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(healthMetricStatisticsProvider.future);
      expect(result['totalMetrics'], 0);
    });
  });

  group('bloodTestsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final repo = FakeBloodTestRepository()..shouldFailGetActive = true;
      final container = buildContainer(bloodTestRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bloodTestsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no tests', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(bloodTestsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('bloodTestStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final repo = FakeBloodTestRepository()..shouldFailUpcoming = true;
      final container = buildContainer(bloodTestRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(bloodTestStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(bloodTestStatisticsProvider.future);
      expect(result['scheduledCount'], 0);
      expect(result['completedCount'], 0);
    });
  });

  group('doctorVisitsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty list', () async {
      final repo = FakeDoctorVisitRepository()..shouldFailGetActive = true;
      final container = buildContainer(doctorVisitRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(doctorVisitsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns an empty list on success when there are no visits', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(doctorVisitsProvider.future);
      expect(result, isEmpty);
    });
  });

  group('doctorVisitStatisticsProvider', () {
    test('surfaces a failed lookup as AsyncError instead of an empty map', () async {
      final repo = FakeDoctorVisitRepository()..shouldFailGetActive = true;
      final container = buildContainer(doctorVisitRepository: repo);
      addTearDown(container.dispose);

      await expectLater(
        container.read(doctorVisitStatisticsProvider.future),
        throwsA(isA<DatabaseError>()),
      );
    });

    test('returns real statistics on success', () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      final result = await container.read(doctorVisitStatisticsProvider.future);
      expect(result['totalVisits'], 0);
      expect(result['nextVisitDate'], isNull);
    });
  });
}
