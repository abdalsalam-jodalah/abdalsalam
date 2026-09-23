import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/models/health/medication.dart';
import '../../../data/models/health/medication_log.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../data/repositories/health/medication_log_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/base_service_impl.dart';
import '../../../shared/services/error_handler.dart';

class MedicationService extends BaseServiceImpl<Medication> {
  final MedicationLogRepository logRepository;
  final _uuid = const Uuid();

  MedicationService({
    required HealthRepository repository,
    required LoggerService logger,
    required this.logRepository,
  }) : super(repository, logger);

  HealthRepository get _repo => repository as HealthRepository;

  ErrorHandler get _errorHandler => ErrorHandler(logger);

  @override
  String get serviceName => 'MedicationService';

  @override
  String get version => '1.0.0';

  @override
  Medication fromJson(Map<String, dynamic> json) => Medication.fromJson(json);

  @override
  Result<void, AppError> validate(Medication entity) {
    if (entity.userId.trim().isEmpty) {
      return Failure(ValidationError('User ID is required'));
    }
    if (entity.name.trim().isEmpty) {
      return Failure(ValidationError('Medication name is required'));
    }
    if (entity.dosage.trim().isEmpty) {
      return Failure(ValidationError('Dosage is required'));
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

    final today = DateTime.now();
    final logsResult = await logRepository.getByDate(today);
    if (logsResult.isFailure) {
      return Failure(logsResult.error!);
    }

    final logs = logsResult.data!;
    final taken = logs.where((log) => log.isTaken).length;
    final total = logs.length;
    final adherence = total > 0 ? (taken / total * 100).toStringAsFixed(1) : '0.0';

    return Success(<String, dynamic>{
      'activeMedications': all.data!.length,
      'todayTotal': total,
      'todayTaken': taken,
      'todayPending': logs.where((log) => log.isPending).length,
      'adherenceRate': adherence,
    });
  }

  /// Reorder medications by updating their displayOrder
  Future<Result<void, AppError>> reorderMedications(List<String> medicationIds) async {
    try {
      final medications = <Medication>[];
      for (var i = 0; i < medicationIds.length; i++) {
        final result = await repository.getById(medicationIds[i]);
        if (result.isFailure) {
          return Failure(result.error!);
        }
        final medication = result.data;
        if (medication == null) {
          logger.warning('[$serviceName] Reorder skipped missing medication ${medicationIds[i]}');
          continue;
        }
        medications.add(medication.copyWith(
          displayOrder: i,
          updatedAt: DateTime.now(),
        ));
      }

      final updateResult = await repository.updateBulk(medications);
      if (updateResult.isFailure) {
        return Failure(updateResult.error!);
      }
      logger.info('[$serviceName] Reordered ${medications.length} medications');
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.reorderMedications', stackTrace: st));
    }
  }

  /// Get medications sorted by display order
  Future<Result<List<Medication>, AppError>> getMedicationsSorted() async {
    final result = await _repo.getActive();
    if (result.isFailure) {
      return result;
    }

    final sorted = result.data!..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return Success(sorted);
  }

  /// Generate daily medication logs for a specific date
  Future<Result<void, AppError>> generateDailyLogs(DateTime date, String userId) async {
    try {
      final medicationsResult = await _repo.activeOn(date);
      if (medicationsResult.isFailure) {
        return Failure(medicationsResult.error!);
      }

      final medications = medicationsResult.data!
          .where((m) => m.isActive && m.frequency != 'As Needed')
          .toList();
      final logs = <MedicationLog>[];

      for (final medication in medications) {
        for (final time in medication.reminderTimes) {
          // Check if log already exists
          final existingLog = await logRepository.getLogForMedicationAndTime(
            medication.id,
            date,
            time,
          );

          if (existingLog.isFailure) {
            return Failure(existingLog.error!);
          }

          if (existingLog.data == null) {
            // Create new log
            final log = MedicationLog(
              id: _uuid.v4(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              userId: userId,
              medicationId: medication.id,
              scheduledFor: DateTime(date.year, date.month, date.day),
              scheduledTime: time,
            );
            logs.add(log);
          }
        }
      }

      if (logs.isNotEmpty) {
        final createResult = await logRepository.createBulk(logs);
        if (createResult.isFailure) {
          return Failure(createResult.error!);
        }
        logger.info('[$serviceName] Generated ${logs.length} logs for $date');
      }

      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.generateDailyLogs', stackTrace: st));
    }
  }

  /// Mark a medication as taken
  Future<Result<MedicationLog, AppError>> markAsTaken(
    String medicationId,
    DateTime date,
    String time,
  ) async {
    try {
      final logResult = await logRepository.getLogForMedicationAndTime(
        medicationId,
        date,
        time,
      );

      if (logResult.isFailure) {
        return Failure(logResult.error!);
      }

      if (logResult.data == null) {
        return Failure(NotFoundError('Log not found'));
      }

      final updated = logResult.data!.copyWith(
        takenAt: DateTime.now(),
        skipped: false,
        updatedAt: DateTime.now(),
      );

      final updateResult = await logRepository.update(updated);
      if (updateResult.isFailure) {
        return Failure(updateResult.error!);
      }
      logger.info('[$serviceName] Marked medication $medicationId as taken');
      return Success(updated);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.markAsTaken', stackTrace: st));
    }
  }

  /// Reset all logs for a specific date (uncheck all)
  Future<Result<void, AppError>> resetDailyLogs(DateTime date) async {
    try {
      final logsResult = await logRepository.getByDate(date);
      if (logsResult.isFailure) {
        return Failure(logsResult.error!);
      }

      final logs = logsResult.data!;
      final resetLogs = logs.map((log) => log.copyWith(
            takenAtIsNull: true,
            skipped: false,
            updatedAt: DateTime.now(),
          )).toList();

      final updateResult = await logRepository.updateBulk(resetLogs);
      if (updateResult.isFailure) {
        return Failure(updateResult.error!);
      }
      logger.info('[$serviceName] Reset ${resetLogs.length} logs for $date');
      return const Success(null);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.resetDailyLogs', stackTrace: st));
    }
  }

  /// Get daily checklist with medication details
  Future<Result<List<DailyMedicationCheck>, AppError>> getDailyChecklist(DateTime date) async {
    try {
      final logsResult = await logRepository.getByDate(date);
      if (logsResult.isFailure) {
        return Failure(logsResult.error!);
      }

      final logs = logsResult.data!;
      final checklist = <DailyMedicationCheck>[];

      for (final log in logs) {
        final medResult = await repository.getById(log.medicationId);
        if (medResult.isFailure) {
          return Failure(medResult.error!);
        }
        if (medResult.data != null) {
          checklist.add(DailyMedicationCheck(
            log: log,
            medication: medResult.data!,
          ));
        }
      }

      // Sort by:
      // 1. Checked status (unchecked first)
      // 2. Medication display order
      // 3. Scheduled time
      checklist.sort((a, b) {
        // Unchecked items first
        if (a.isChecked != b.isChecked) {
          return a.isChecked ? 1 : -1;
        }
        // Then by medication display order
        final orderCompare = a.medication.displayOrder.compareTo(b.medication.displayOrder);
        if (orderCompare != 0) return orderCompare;
        // Finally by scheduled time
        return a.log.scheduledTime.compareTo(b.log.scheduledTime);
      });

      return Success(checklist);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.getDailyChecklist', stackTrace: st));
    }
  }

  /// Toggle medication active status
  Future<Result<Medication, AppError>> toggleActive(String medicationId) async {
    try {
      final result = await repository.getById(medicationId);
      if (result.isFailure) {
        return Failure(result.error!);
      }
      final medication = result.data;
      if (medication == null) {
        return Failure(NotFoundError('Medication not found'));
      }

      final updated = medication.copyWith(
        isActive: !medication.isActive,
        updatedAt: DateTime.now(),
      );

      final updateResult = await repository.update(updated);
      if (updateResult.isFailure) {
        return Failure(updateResult.error!);
      }
      logger.info('[$serviceName] Toggled medication $medicationId active status');
      return Success(updated);
    } catch (e, st) {
      return Failure(_errorHandler.mapException(e, context: '$serviceName.toggleActive', stackTrace: st));
    }
  }
}

/// Helper class for daily checklist
class DailyMedicationCheck {
  final MedicationLog log;
  final Medication medication;

  const DailyMedicationCheck({
    required this.log,
    required this.medication,
  });

  bool get isChecked => log.isTaken;
  String get displayTime => log.scheduledTime;
  String get medicationName => medication.name;
  String get dosage => medication.dosage;
}
