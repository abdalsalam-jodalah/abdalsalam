import '../infrastructure/logger_service.dart';
import '../infrastructure/storage_gateway.dart';
import 'reminder_service.dart';

/// Ensures today's sleep and food logging reminders are scheduled even if
/// the sleep or food screens are never opened on a given day.
class WellnessReminderRolloverService {
  static const _lastRunKey = 'wellness_reminder_rollover_last_run';
  static const _sleepReminderHour = 22;
  static const _foodReminderHour = 19;
  static const _foodReminderMinute = 30;

  final ReminderService reminderService;
  final StorageGateway storage;
  final LoggerService logger;

  WellnessReminderRolloverService({
    required this.reminderService,
    required this.storage,
    required this.logger,
  });

  Future<void> runIfNeeded() async {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final lastRun = await storage.get<String>(_lastRunKey);
    if (lastRun == todayKey) {
      return;
    }

    await reminderService.scheduleSleepReminder(
      time: DateTime(today.year, today.month, today.day, _sleepReminderHour),
    );
    await reminderService.scheduleFoodReminder(
      time: DateTime(today.year, today.month, today.day, _foodReminderHour, _foodReminderMinute),
      mealLabel: 'dinner',
    );

    await storage.save(key: _lastRunKey, value: todayKey);
    logger.info('[WellnessReminderRolloverService] rollover completed for $todayKey');
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
