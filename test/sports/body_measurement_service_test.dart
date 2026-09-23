import 'package:abdalsalam/data/models/sports/body_measurement.dart';
import 'package:abdalsalam/data/repositories/sports/body_measurement_repository.dart';
import 'package:abdalsalam/features/sports/services/body_measurement_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:abdalsalam/shared/infrastructure/storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/failing_writes.dart';
import '../support/test_storage.dart';
import '../support/validation_expectations.dart';

class _FailingBodyMeasurementRepository = BodyMeasurementRepositoryImpl with FailingWrites<BodyMeasurement>;

BodyMeasurement _measurement({
  String userId = 'u1',
  double weightKg = 80,
  double? heightCm = 180,
  double? bodyFatPercent = 18,
  double? waistCm = 85,
}) {
  final now = DateTime(2026, 5, 1);
  return BodyMeasurement(
    id: 'measurement-1',
    createdAt: now,
    updatedAt: now,
    userId: userId,
    date: now,
    weightKg: weightKg,
    heightCm: heightCm,
    bodyFatPercent: bodyFatPercent,
    waistCm: waistCm,
  );
}

void main() {
  initializeTestDatabaseFactory();

  late LoggerService logger;
  late BodyMeasurementService service;

  setUp(() async {
    await resetTestStorage(
      databaseName: 'test_body_measurement_service_test.db',
      tables: ['sport_body_measurements'],
    );
    logger = LoggerService.forModule('BodyMeasurementServiceTest');
    service = BodyMeasurementService(BodyMeasurementRepositoryImpl(StorageGateway.instance, logger), logger);
  });

  group('BodyMeasurementService.validate', () {
    test('should succeed for a well-formed measurement', () {
      expect(service.validate(_measurement()).isSuccess, isTrue);
    });

    test('should succeed when optional measurements are absent', () {
      final result = service.validate(_measurement(heightCm: null, bodyFatPercent: null, waistCm: null));
      expect(result.isSuccess, isTrue);
    });

    test('should report userId when userId is blank', () {
      expectFieldError(service.validate(_measurement(userId: '')), BodyMeasurementService.userIdField);
    });

    test('should report weightKg when weight is zero', () {
      expectFieldError(service.validate(_measurement(weightKg: 0)), BodyMeasurementService.weightKgField);
    });

    test('should report heightCm when height is negative', () {
      expectFieldError(service.validate(_measurement(heightCm: -1)), BodyMeasurementService.heightCmField);
    });

    test('should report bodyFatPercent when body fat is above 100', () {
      expectFieldError(
        service.validate(_measurement(bodyFatPercent: 101)),
        BodyMeasurementService.bodyFatPercentField,
      );
    });

    test('should report waistCm when waist is zero', () {
      expectFieldError(service.validate(_measurement(waistCm: 0)), BodyMeasurementService.waistCmField);
    });
  });

  group('BodyMeasurementService writes', () {
    test('should persist a created measurement', () async {
      final result = await service.create(_measurement());

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('measurement-1');
      expect(stored.data?.weightKg, 80);
    });

    test('should persist an updated measurement', () async {
      await service.create(_measurement());

      final result = await service.update(_measurement(weightKg: 78.5));

      expect(result.isSuccess, isTrue);
      final stored = await service.getById('measurement-1');
      expect(stored.data?.weightKg, 78.5);
    });

    test('should propagate a repository create failure', () async {
      final failingService =
          BodyMeasurementService(_FailingBodyMeasurementRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.create(_measurement()));
    });

    test('should propagate a repository update failure', () async {
      final failingService =
          BodyMeasurementService(_FailingBodyMeasurementRepository(StorageGateway.instance, logger), logger);

      expectWriteFailure(await failingService.update(_measurement()));
    });
  });
}
