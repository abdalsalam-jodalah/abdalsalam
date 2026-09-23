import 'package:abdalsalam/data/models/health/doctor_visit.dart';
import 'package:abdalsalam/features/health/services/doctor_visit_service.dart';
import 'package:abdalsalam/shared/infrastructure/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final visitDate = DateTime(2026, 3, 1);
  late FakeDoctorVisitRepository visits;
  late FakeAttachmentStorageService attachments;
  late DoctorVisitService service;

  DoctorVisit buildVisit({List<String> attachmentPaths = const <String>['a.pdf', 'b.pdf']}) {
    return DoctorVisit(
      id: 'visit-1',
      createdAt: visitDate,
      updatedAt: visitDate,
      userId: 'user',
      doctorName: 'Dr. Salem',
      visitDate: visitDate,
      reason: 'Checkup',
      attachmentPaths: attachmentPaths,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LoggerService.initialize();
    visits = FakeDoctorVisitRepository([buildVisit()]);
    attachments = FakeAttachmentStorageService();
    service = DoctorVisitService(visits, LoggerService.forModule('DoctorVisitServiceTest'), attachments: attachments);
  });

  group('DoctorVisitService.deleteWithAttachments', () {
    test('should soft delete the visit and remove its files', () async {
      final result = await service.deleteWithAttachments('visit-1');

      expect(result.isSuccess, isTrue);
      expect(visits.softDeletedIds, ['visit-1']);
      expect(attachments.deletedPaths, ['a.pdf', 'b.pdf']);
    });

    test('should keep the files when the soft delete fails', () async {
      visits.shouldFailSoftDelete = true;

      final result = await service.deleteWithAttachments('visit-1');

      expect(result.isFailure, isTrue);
      expect(attachments.deletedPaths, isEmpty);
    });

    test('should return Failure without deleting when the lookup fails', () async {
      visits.shouldFailGetById = true;

      final result = await service.deleteWithAttachments('visit-1');

      expect(result.isFailure, isTrue);
      expect(visits.softDeletedIds, isEmpty);
    });

    test('should still succeed when only the file cleanup fails', () async {
      attachments.shouldFailDelete = true;

      final result = await service.deleteWithAttachments('visit-1');

      expect(result.isSuccess, isTrue);
      expect(visits.softDeletedIds, ['visit-1']);
    });
  });

  group('DoctorVisitService.updateWithAttachmentCleanup', () {
    test('should remove only the files no longer referenced after saving', () async {
      final result = await service.updateWithAttachmentCleanup(buildVisit(), buildVisit(attachmentPaths: ['a.pdf']));

      expect(result.isSuccess, isTrue);
      expect(attachments.deletedPaths, ['b.pdf']);
    });

    test('should keep the files when the update fails', () async {
      visits.shouldFailUpdate = true;

      final result = await service.updateWithAttachmentCleanup(buildVisit(), buildVisit(attachmentPaths: ['a.pdf']));

      expect(result.isFailure, isTrue);
      expect(attachments.deletedPaths, isEmpty);
    });
  });

  group('DoctorVisitService.getStatistics', () {
    test('should return Failure when the next visit lookup fails', () async {
      visits.shouldFailNextUpcoming = true;

      final result = await service.getStatistics();

      expect(result.isFailure, isTrue);
    });
  });
}
