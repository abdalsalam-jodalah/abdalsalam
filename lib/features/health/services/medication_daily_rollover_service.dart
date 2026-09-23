import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../data/repositories/health/health_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import '../../../shared/services/daily_run_marker.dart';
import '../../../shared/services/error_handler.dart';
import 'health_service.dart';
import 'medication_service.dart';

class MedicationDailyRolloverService {
  static const _lastRunKey = 'medication_daily_rollover_last_run';
  static const _logContext = 'MedicationDailyRolloverService';

  final MedicationService medicationService;
  final HealthService healthService;
  final HealthRepository healthRepository;
  final StorageGateway storage;
  final LoggerService logger;
  final DateTime Function() clock;

  MedicationDailyRolloverService({
    required this.medicationService,
    required this.healthService,
    required this.healthRepository,
    required this.storage,
    required this.logger,
    this.clock = DateTime.now,
  });

  DailyRunMarker get _runMarker => DailyRunMarker(storage: storage, storageKey: _lastRunKey);

  Future<Result<void, AppError>> runIfNeeded({String userId = 'current_user_id'}) async {
    try {
      final today = clock();
      if (await _runMarker.hasRunOn(today)) {
        return const Success(null);
      }

      final generateResult = await medicationService.generateDailyLogs(today, userId);
      if (generateResult.isFailure) {
        logger.error('[$_logContext] generating daily logs failed', error: generateResult.error);
        return Failure(generateResult.error!);
      }

      final activeResult = await healthRepository.getActive();
      if (activeResult.isFailure) {
        logger.error('[$_logContext] loading active medications failed', error: activeResult.error);
        return Failure(activeResult.error!);
      }

      AppError? firstReminderError;
      for (final medication in activeResult.data!) {
        final refreshResult = await healthService.refreshReminders(medication);
        if (refreshResult.isFailure) {
          logger.error('[$_logContext] refreshing reminders for ${medication.id} failed', error: refreshResult.error);
          firstReminderError ??= refreshResult.error;
        }
      }
      if (firstReminderError != null) {
        return Failure(firstReminderError);
      }

      await _runMarker.markRunOn(today);
      logger.info('[$_logContext] rollover completed for $today');
      return const Success(null);
    } catch (e, st) {
      return Failure(ErrorHandler(logger).mapException(e, context: '$_logContext.runIfNeeded', stackTrace: st));
    }
  }
}
