import 'package:abdalsalam/core/errors/app_error.dart';
import 'package:abdalsalam/core/result/result.dart';
import 'package:abdalsalam/data/models/base_model.dart';
import 'package:abdalsalam/data/models/health/blood_test.dart';
import 'package:abdalsalam/data/models/health/doctor_visit.dart';
import 'package:abdalsalam/data/models/health/health_metric.dart';
import 'package:abdalsalam/data/models/health/medication.dart';
import 'package:abdalsalam/data/models/health/medication_log.dart';
import 'package:abdalsalam/data/repositories/health/blood_test_repository.dart';
import 'package:abdalsalam/data/repositories/health/doctor_visit_repository.dart';
import 'package:abdalsalam/data/repositories/health/health_metric_repository.dart';
import 'package:abdalsalam/data/repositories/health/health_repository.dart';
import 'package:abdalsalam/data/repositories/health/medication_log_repository.dart';
import 'package:abdalsalam/shared/services/attachment_storage_service.dart';
import 'package:abdalsalam/shared/services/reminder_service.dart';

AppError fakeStorageFailure() => DatabaseError('fake storage failure');

class FakeCrudRepository<T extends BaseModel> {
  final List<T> items;
  bool shouldFailGetById = false;
  bool shouldFailGetActive = false;
  bool shouldFailUpdate = false;
  bool shouldFailUpdateBulk = false;
  bool shouldFailCreateBulk = false;
  bool shouldFailSoftDelete = false;
  bool shouldThrowOnGetActive = false;
  bool shouldThrowOnGetById = false;
  final List<String> softDeletedIds = <String>[];

  FakeCrudRepository([List<T>? seed]) : items = seed ?? <T>[];

  Future<Result<T?, AppError>> getById(String id) async {
    if (shouldThrowOnGetById) {
      throw StateError('fake getById crash');
    }
    if (shouldFailGetById) {
      return Failure(fakeStorageFailure());
    }
    final matches = items.where((item) => item.id == id);
    return Success(matches.isEmpty ? null : matches.first);
  }

  Future<Result<List<T>, AppError>> getActive() async {
    if (shouldThrowOnGetActive) {
      throw StateError('fake getActive crash');
    }
    if (shouldFailGetActive) {
      return Failure(fakeStorageFailure());
    }
    return Success(List<T>.of(items));
  }

  Future<Result<void, AppError>> update(T entity) async {
    if (shouldFailUpdate) {
      return Failure(fakeStorageFailure());
    }
    _replace(entity);
    return const Success(null);
  }

  Future<Result<void, AppError>> updateBulk(List<T> entities) async {
    if (shouldFailUpdateBulk) {
      return Failure(fakeStorageFailure());
    }
    entities.forEach(_replace);
    return const Success(null);
  }

  Future<Result<List<T>, AppError>> createBulk(List<T> entities) async {
    if (shouldFailCreateBulk) {
      return Failure(fakeStorageFailure());
    }
    items.addAll(entities);
    return Success(entities);
  }

  Future<Result<void, AppError>> softDelete(String id) async {
    if (shouldFailSoftDelete) {
      return Failure(fakeStorageFailure());
    }
    softDeletedIds.add(id);
    return const Success(null);
  }

  void _replace(T entity) {
    final index = items.indexWhere((item) => item.id == entity.id);
    if (index == -1) {
      items.add(entity);
    } else {
      items[index] = entity;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeHealthRepository extends FakeCrudRepository<Medication> implements HealthRepository {
  bool shouldFailActiveOn = false;

  FakeHealthRepository([super.seed]);

  @override
  Future<Result<List<Medication>, AppError>> activeOn(DateTime date) async {
    if (shouldFailActiveOn) {
      return Failure(fakeStorageFailure());
    }
    return Success(items.where((medication) => medication.isActive).toList());
  }
}

class FakeMedicationLogRepository extends FakeCrudRepository<MedicationLog> implements MedicationLogRepository {
  bool shouldFailLookup = false;

  FakeMedicationLogRepository([super.seed]);

  @override
  Future<Result<List<MedicationLog>, AppError>> getByDate(DateTime date) async {
    if (shouldFailLookup) {
      return Failure(fakeStorageFailure());
    }
    return Success(items.where((log) => _isSameDay(log.scheduledFor, date)).toList());
  }

  @override
  Future<Result<MedicationLog?, AppError>> getLogForMedicationAndTime(
    String medicationId,
    DateTime date,
    String time,
  ) async {
    if (shouldFailLookup) {
      return Failure(fakeStorageFailure());
    }
    final matches = items.where(
      (log) => log.medicationId == medicationId && log.scheduledTime == time && _isSameDay(log.scheduledFor, date),
    );
    return Success(matches.isEmpty ? null : matches.first);
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class FakeHealthMetricRepository extends FakeCrudRepository<HealthMetric> implements HealthMetricRepository {
  FakeHealthMetricRepository([super.seed]);
}

class FakeBloodTestRepository extends FakeCrudRepository<BloodTest> implements BloodTestRepository {
  bool shouldFailUpcoming = false;
  bool shouldFailCompleted = false;

  FakeBloodTestRepository([super.seed]);

  @override
  Future<Result<List<BloodTest>, AppError>> getUpcoming() async {
    if (shouldFailUpcoming) {
      return Failure(fakeStorageFailure());
    }
    return Success(items.where((test) => test.completedDate == null).toList());
  }

  @override
  Future<Result<List<BloodTest>, AppError>> getCompleted() async {
    if (shouldFailCompleted) {
      return Failure(fakeStorageFailure());
    }
    return Success(items.where((test) => test.completedDate != null).toList());
  }
}

class FakeDoctorVisitRepository extends FakeCrudRepository<DoctorVisit> implements DoctorVisitRepository {
  bool shouldFailNextUpcoming = false;

  FakeDoctorVisitRepository([super.seed]);

  @override
  Future<Result<DoctorVisit?, AppError>> getNextUpcoming() async {
    if (shouldFailNextUpcoming) {
      return Failure(fakeStorageFailure());
    }
    return const Success(null);
  }
}

class FakeReminderService implements ReminderService {
  final List<ReminderPayload> scheduled = <ReminderPayload>[];
  final List<String> cancelledTargetIds = <String>[];
  bool shouldThrowOnSchedule = false;

  @override
  Future<void> schedule(ReminderPayload payload) async {
    if (shouldThrowOnSchedule) {
      throw StateError('fake notification plugin failure');
    }
    scheduled.add(payload);
  }

  @override
  Future<void> cancel(ReminderModule module, String targetId) async {
    cancelledTargetIds.add(targetId);
  }

  @override
  Future<void> scheduleSleepReminder({required DateTime time}) {
    return schedule(ReminderPayload(
      module: ReminderModule.sleep,
      targetId: 'sleep',
      title: 'sleep',
      body: 'sleep',
      scheduledAt: time,
    ));
  }

  @override
  Future<void> scheduleFoodReminder({required DateTime time, required String mealLabel}) {
    return schedule(ReminderPayload(
      module: ReminderModule.food,
      targetId: mealLabel,
      title: 'food',
      body: 'food',
      scheduledAt: time,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class FakeAttachmentStorageService implements AttachmentStorageService {
  final List<String> deletedPaths = <String>[];
  bool shouldFailDelete = false;

  @override
  Future<Result<void, AppError>> deleteAttachments(List<String> paths) async {
    if (shouldFailDelete) {
      return Failure(ServiceError('fake file system failure'));
    }
    deletedPaths.addAll(paths);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

Medication buildMedication({
  String id = 'med-1',
  List<String> reminderTimes = const <String>['08:00'],
  String frequency = 'Daily',
  bool isActive = true,
  int displayOrder = 0,
  DateTime? refillDate,
}) {
  final created = DateTime(2026, 1, 1);
  return Medication(
    id: id,
    createdAt: created,
    updatedAt: created,
    userId: 'user',
    name: 'Vitamin D',
    dosage: '1000 IU',
    frequency: frequency,
    startDate: created,
    reminderTimes: reminderTimes,
    isActive: isActive,
    displayOrder: displayOrder,
    refillDate: refillDate,
  );
}

MedicationLog buildMedicationLog({
  String id = 'log-1',
  String medicationId = 'med-1',
  String time = '08:00',
  required DateTime scheduledFor,
}) {
  return MedicationLog(
    id: id,
    createdAt: scheduledFor,
    updatedAt: scheduledFor,
    userId: 'user',
    medicationId: medicationId,
    scheduledFor: scheduledFor,
    scheduledTime: time,
  );
}
