import '../../../data/repositories/health/health_repository.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/infrastructure/storage_gateway.dart';
import 'health_service.dart';
import 'medication_service.dart';

/// Ensures today's medication logs exist and reminders are (re)scheduled
/// even if the medication list screen is never opened on a given day.
class MedicationDailyRolloverService {
  static const _lastRunKey = 'medication_daily_rollover_last_run';

  final MedicationService medicationService;
  final HealthService healthService;
  final HealthRepository healthRepository;
  final StorageGateway storage;
  final LoggerService logger;

  MedicationDailyRolloverService({
    required this.medicationService,
    required this.healthService,
    required this.healthRepository,
    required this.storage,
    required this.logger,
  });

  Future<void> runIfNeeded({String userId = 'current_user_id'}) async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastRun = await storage.get<String>(_lastRunKey);
    if (lastRun == todayKey) {
      return;
    }

    await medicationService.generateDailyLogs(today, userId);

    final activeResult = await healthRepository.getActive();
    if (activeResult.isSuccess) {
      for (final medication in activeResult.data!) {
        await healthService.refreshReminders(medication);
      }
    }

    await storage.save(key: _lastRunKey, value: todayKey);
    logger.info('[MedicationDailyRolloverService] rollover completed for $todayKey');
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
