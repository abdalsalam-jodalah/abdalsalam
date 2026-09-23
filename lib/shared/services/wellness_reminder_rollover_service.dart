import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'daily_run_marker.dart';
import 'error_handler.dart';
import 'reminder_service.dart';

class WellnessReminderRolloverService {
  static const _lastRunKey = 'wellness_reminder_rollover_last_run';
  static const _logContext = 'WellnessReminderRolloverService';
  static const _sleepReminderHour = 22;
  static const _foodReminderHour = 19;
  static const _foodReminderMinute = 30;
  static const _foodReminderMealLabel = 'dinner';

  final ReminderService reminderService;
  final StorageGateway storage;
  final LoggerService logger;
  final DateTime Function() clock;

  WellnessReminderRolloverService({
    required this.reminderService,
    required this.storage,
    required this.logger,
    this.clock = DateTime.now,
  });

  DailyRunMarker get _runMarker => DailyRunMarker(storage: storage, storageKey: _lastRunKey);

  Future<Result<void, AppError>> runIfNeeded() async {
    try {
      final today = clock();
      if (await _runMarker.hasRunOn(today)) {
        return const Success(null);
      }

      await reminderService.scheduleSleepReminder(
        time: DateTime(today.year, today.month, today.day, _sleepReminderHour),
      );
      await reminderService.scheduleFoodReminder(
        time: DateTime(today.year, today.month, today.day, _foodReminderHour, _foodReminderMinute),
        mealLabel: _foodReminderMealLabel,
      );

      await _runMarker.markRunOn(today);
      logger.info('[$_logContext] rollover completed for $today');
      return const Success(null);
    } catch (e, st) {
      return Failure(ErrorHandler(logger).mapException(e, context: '$_logContext.runIfNeeded', stackTrace: st));
    }
  }
}
