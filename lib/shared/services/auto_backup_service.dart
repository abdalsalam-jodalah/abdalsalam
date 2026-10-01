// lib/shared/services/auto_backup_service.dart — creates a rotating local backup when automatic backup is on and one is due.

import '../../core/errors/app_error.dart';
import '../../core/result/result.dart';
import '../infrastructure/logger_service.dart';
import 'backup_service.dart';
import 'backup_status_service.dart';
import 'error_handler.dart';
import 'settings_service.dart';

class AutoBackupService {
  static const String enabledSettingKey = 'autoBackupEnabled';
  static const String intervalDaysSettingKey = 'backupReminderDays';
  static const int defaultIntervalDays = 7;

  final BackupService backups;
  final BackupStatusService status;
  final SettingsService settings;
  final LoggerService logger;
  final DateTime Function() _clock;

  AutoBackupService({
    required this.backups,
    required this.status,
    required this.settings,
    required this.logger,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  Future<Result<bool, AppError>> runIfDue() async {
    try {
      final values = await settings.getSettings();
      if (values[enabledSettingKey] != true) {
        return const Success(false);
      }
      final intervalDays = values[intervalDaysSettingKey] is int
          ? values[intervalDaysSettingKey] as int
          : defaultIntervalDays;
      final lastAutoBackupAt = (await status.read()).lastAutoBackupAt;
      if (lastAutoBackupAt != null && _clock().difference(lastAutoBackupAt) < Duration(days: intervalDays)) {
        return const Success(false);
      }
      final created = await backups.createAutomaticBackup();
      if (created.isFailure) {
        logger.warning('[AutoBackupService] automatic backup failed: ${created.error}');
        return Failure(created.error!);
      }
      await status.recordAutoBackup();
      logger.info('[AutoBackupService] automatic backup saved path=${created.data}');
      return const Success(true);
    } catch (error, stackTrace) {
      return Failure(ErrorHandler(logger).mapException(error, context: 'AutoBackupService.runIfDue', stackTrace: stackTrace));
    }
  }
}
