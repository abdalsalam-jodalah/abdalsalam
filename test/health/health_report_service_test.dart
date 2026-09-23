import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/features/health/services/blood_test_service.dart';
import 'package:abdalsalam/features/health/services/doctor_visit_service.dart';
import 'package:abdalsalam/features/health/services/health_metric_service.dart';
import 'package:abdalsalam/features/health/services/health_report_service.dart';
import 'package:abdalsalam/features/health/services/medication_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHealthRepository medications;
  late FakeHealthMetricRepository metrics;
  late FakeBloodTestRepository bloodTests;
  late FakeDoctorVisitRepository visits;
  late HealthReportService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    final logger = LoggerService.forModule('HealthReportServiceTest');
    medications = FakeHealthRepository([buildMedication()]);
    metrics = FakeHealthMetricRepository();
    bloodTests = FakeBloodTestRepository();
    visits = FakeDoctorVisitRepository();
    service = HealthReportService(
      medicationService: MedicationService(
        repository: medications,
        logger: logger,
        logRepository: FakeMedicationLogRepository(),
      ),
      healthMetricService: HealthMetricService(metrics, logger),
      bloodTestService: BloodTestService(bloodTests, logger),
      doctorVisitService: DoctorVisitService(visits, logger, attachments: FakeAttachmentStorageService()),
      logger: logger,
    );
  });

  group('HealthReportService.generateReport', () {
    test('should return PDF bytes when every source loads', () async {
      final result = await service.generateReport();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotEmpty);
    });

    test('should return Failure instead of an incomplete report when a source fails', () async {
      metrics.shouldFailGetActive = true;

      final result = await service.generateReport();

      expect(result.error, isA<DatabaseError>());
    });

    test('should return Failure instead of throwing when a source crashes', () async {
      bloodTests.shouldThrowOnGetActive = true;

      final result = await service.generateReport();

      expect(result.isFailure, isTrue);
    });
  });

  group('HealthReportService.shareReport', () {
    test('should return Failure without sharing when the report cannot be built', () async {
      visits.shouldFailGetActive = true;

      final result = await service.shareReport();

      expect(result.isFailure, isTrue);
    });
  });
}
