import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/health_metric.dart';
import '../../../data/models/health/medication.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';
import '../../../shared/services/reminder_service.dart';

class HealthService extends BaseServiceImpl<Medication> {
  static const String _reminderTimeSeparator = ':';
  static const int _maxHour = 23;
  static const int _maxMinute = 59;

  final ReminderService reminders;

  HealthService(super.repository, super.logger, {required this.reminders});

  HealthRepository get _repo => repository as HealthRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

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
    try {
      for (final time in medication.reminderTimes) {
        final scheduledAt = _nextOccurrence(time);
        if (scheduledAt == null) {
          logger.warning('[$serviceName] skipped reminder for ${medication.id}: invalid time "$time"');
          continue;
        }
        await reminders.schedule(
          ReminderPayload(
            module: ReminderModule.health,
            targetId: medication.id,
            title: 'Medication reminder',
            body: 'Time to take ${medication.name} (${medication.dosage})',
            scheduledAt: scheduledAt,
            // Weekly meds only fire on selected weekdays, so they can't use a
            // simple daily-recurring notification.
            recurringDaily: medication.weekDays.isEmpty,
            metadata: <String, dynamic>{'time': time},
          ),
        );
      }
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.scheduleMedicationReminders', stackTrace: st));
    }
  }

  /// Cancels any existing reminders for a medication, then reschedules dose
  /// and refill reminders based on its current active/frequency/refillDate state.
  Future<Result<void, AppError>> refreshReminders(Medication medication) async {
    final cancelResult = await cancelReminders(medication.id);
    if (cancelResult.isFailure) {
      return cancelResult;
    }
    if (!medication.isActive) {
      return const Success(null);
    }
    final doseResult = await scheduleMedicationReminders(medication);
    if (doseResult.isFailure) {
      return doseResult;
    }
    return scheduleRefillReminder(medication);
  }

  Future<Result<void, AppError>> cancelReminders(String medicationId) async {
    try {
      await reminders.cancel(ReminderModule.health, medicationId);
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.cancelReminders', stackTrace: st));
    }
  }

  DateTime? _nextOccurrence(String reminderTime) {
    final parts = reminderTime.split(_reminderTimeSeparator);
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null || hour < 0 || hour > _maxHour || minute < 0 || minute > _maxMinute) {
      return null;
    }
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
    try {
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
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.scheduleRefillReminder', stackTrace: st));
    }
  }

  Future<Result<void, AppError>> handleReminderTap(Medication medication) async {
    try {
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
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.handleReminderTap', stackTrace: st));
    }
  }
}
