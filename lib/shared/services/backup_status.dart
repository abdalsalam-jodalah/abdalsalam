// lib/shared/services/backup_status.dart — when data was last backed up, used to decide reminders and automatic backups.

import '../../core/json/json_reader.dart';

class BackupStatus {
  static const String _trackingStartedAtField = 'trackingStartedAt';
  static const String _lastExportedAtField = 'lastExportedAt';
  static const String _lastAutoBackupAtField = 'lastAutoBackupAt';

  final DateTime? trackingStartedAt;
  final DateTime? lastExportedAt;
  final DateTime? lastAutoBackupAt;

  const BackupStatus({this.trackingStartedAt, this.lastExportedAt, this.lastAutoBackupAt});

  factory BackupStatus.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json, source: 'BackupStatus');
    return BackupStatus(
      trackingStartedAt: reader.optionalDate(_trackingStartedAtField),
      lastExportedAt: reader.optionalDate(_lastExportedAtField),
      lastAutoBackupAt: reader.optionalDate(_lastAutoBackupAtField),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        _trackingStartedAtField: trackingStartedAt?.toIso8601String(),
        _lastExportedAtField: lastExportedAt?.toIso8601String(),
        _lastAutoBackupAtField: lastAutoBackupAt?.toIso8601String(),
      };

  BackupStatus copyWith({DateTime? trackingStartedAt, DateTime? lastExportedAt, DateTime? lastAutoBackupAt}) {
    return BackupStatus(
      trackingStartedAt: trackingStartedAt ?? this.trackingStartedAt,
      lastExportedAt: lastExportedAt ?? this.lastExportedAt,
      lastAutoBackupAt: lastAutoBackupAt ?? this.lastAutoBackupAt,
    );
  }

  int? daysSinceLastExport(DateTime now) {
    final reference = lastExportedAt ?? trackingStartedAt;
    return reference == null ? null : now.difference(reference).inDays;
  }

  bool isExportReminderDue({required int reminderDays, required DateTime now}) {
    final days = daysSinceLastExport(now);
    return days != null && days >= reminderDays;
  }
}
