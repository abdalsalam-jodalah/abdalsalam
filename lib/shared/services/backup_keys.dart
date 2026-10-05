class BackupKeys {
  const BackupKeys._();

  static const String currentVersion = '2.0.0';
  static const String previousVersion = '1.1.0';
  static const String legacyVersion = '1.0.0';
  static const Set<String> supportedVersions = <String>{currentVersion, previousVersion, legacyVersion};
  static const String metadata = 'metadata';
  static const String data = 'data';
  static const String preferences = 'preferences';
  static const String version = 'version';
  static const String checksum = 'checksum';
  static const String preferencesChecksum = 'preferencesChecksum';
  static const String tables = 'tables';
  static const String createdAt = 'createdAt';
  static const String attachmentCount = 'attachmentCount';

  static const String archiveBackupEntry = 'backup.json';
  static const String archiveManifestEntry = 'manifest.json';
  static const String archiveAttachmentsPrefix = 'attachments/';

  static const Set<String> transientPreferenceKeys = <String>{
    'weather_data',
    'weather_last_update',
    'currency_rates',
    'currency_rates_last_update',
    'prayer_times_cache',
    'medication_daily_rollover_last_run',
    'wellness_reminder_rollover_last_run',
    'sync_queue',
    'backup_status_v1',
    'sync_history_v1',
  };
}
