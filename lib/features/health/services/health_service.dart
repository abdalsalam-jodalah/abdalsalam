import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../data/models/health/medication.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/reminder_service.dart';

class HealthService extends BaseServiceImpl<Medication> {
  final ReminderService reminders;

  HealthService(super.repository, super.logger, {required this.reminders});

  HealthRepository get _repo => repository as HealthRepository;

  @override
  String get serviceName => 'HealthService';

  @override
  String get version => '2.0.0';

  @override
  Medication fromJson(Map<String, dynamic> json) => Medication.fromJson(json);

  @override
  Result<void, AppError> validate(Medication entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('userId is required'));
    }
    if (entity.name.trim().isEmpty) {
      return Failure(ValidationError('name is required'));
    }
    if (entity.reminderTimes.isEmpty) {
      return Failure(ValidationError('At least one reminder time is required'));
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>, AppError>> getStatistics() async {
    final all = await _repo.getActive();
    if (all.isFailure) {
      return Failure(all.error!);
    }

    return Success(<String, dynamic>{
      'medications': all.data!.length,
      'adherenceRate': 100.0,
      'metricTrend': 'stable',
    });
  }

  double adherenceRate({required int taken, required int total}) {
    if (total <= 0) {
      return 0;
    }
    return (taken / total) * 100;
  }

  Map<String, double> metricTrend(List<HealthMetric> metrics) {
    final out = <String, double>{};
    for (final m in metrics) {
      out[m.metricType] = m.value;
    }
    return out;
  }

  Future<Result<void, AppError>> scheduleMedicationReminders(Medication medication) async {
    for (final _ in medication.reminderTimes) {
      await reminders.schedule(
        ReminderPayload(
          module: ReminderModule.health,
          targetId: medication.id,
          title: 'Medication reminder',
          body: 'Time to take ${medication.name} (${medication.dosage})',
          scheduledAt: DateTime.now(),
        ),
      );
    }
    return const Success(null);
  }

  Future<Result<void, AppError>> scheduleRefillReminder(Medication medication) async {
    if (medication.refillDate == null) {
      return const Success(null);
    }
    await reminders.schedule(
      ReminderPayload(
        module: ReminderModule.health,
        targetId: medication.id,
        title: 'Refill reminder',
        body: 'Refill ${medication.name} in 3 days',
        scheduledAt: medication.refillDate!.subtract(const Duration(days: 3)),
      ),
    );
    return const Success(null);
  }

  Future<Result<void, AppError>> handleReminderTap(Medication medication) async {
    reminders.handleNotificationTap(
      ReminderPayload(
        module: ReminderModule.health,
        targetId: medication.id,
        title: 'Open medication',
        body: medication.name,
        scheduledAt: DateTime.now(),
      ),
    );
    return const Success(null);
  }
}
