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
    if (medication.frequency == 'As Needed') {
      return const Success(null);
    }
    for (final time in medication.reminderTimes) {
      await reminders.schedule(
        ReminderPayload(
          module: ReminderModule.health,
          targetId: medication.id,
          title: 'Medication reminder',
          body: 'Time to take ${medication.name} (${medication.dosage})',
          scheduledAt: _nextOccurrence(time),
          // Weekly meds only fire on selected weekdays, so they can't use a
          // simple daily-recurring notification.
          recurringDaily: medication.weekDays.isEmpty,
          metadata: <String, dynamic>{'time': time},
        ),
      );
    }
    return const Success(null);
  }

  /// Cancels any existing reminders for a medication, then reschedules dose
  /// and refill reminders based on its current active/frequency/refillDate state.
  Future<Result<void, AppError>> refreshReminders(Medication medication) async {
    await reminders.cancel(ReminderModule.health, medication.id);
    if (!medication.isActive) {
      return const Success(null);
    }
    await scheduleMedicationReminders(medication);
    await scheduleRefillReminder(medication);
    return const Success(null);
  }

  Future<Result<void, AppError>> cancelReminders(String medicationId) async {
    await reminders.cancel(ReminderModule.health, medicationId);
    return const Success(null);
  }

  DateTime _nextOccurrence(String reminderTime) {
    final parts = reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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
