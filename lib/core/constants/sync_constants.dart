// lib/core/constants/sync_constants.dart — tunable values, keys and route name for USB device sync.

class SyncConstants {
  const SyncConstants._();

  static const String routeName = '/settings/sync';
  static const String reportRouteName = '/settings/sync/report';
  static const String historyPreferenceKey = 'sync_history_v1';
  static const String remindersPreferenceKey = 'scheduled_reminders';

  static const String loopbackHost = '127.0.0.1';
  static const int defaultPort = 47821;
  static const int protocolVersion = 1;

  static const int pinLength = 6;
  static const int maxFailedPinAttempts = 5;
  static const int sessionTokenByteLength = 32;
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  static const int maxRequestBodyBytes = 64 * 1024 * 1024;
  static const int rowBatchSize = 200;
  static const int attachmentRowBatchSize = 4;
  static const int historyLimit = 20;

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration requestTimeout = Duration(minutes: 2);
  static const Duration sessionIdleTimeout = Duration(minutes: 2);
  static const Duration clockSkewWarningThreshold = Duration(minutes: 2);

  static const String unknownModuleKey = 'other';
  static const String safetyBackupFilePrefix = 'abdalsalam-pre-sync-';
  static const String safetyBackupFileExtension = '.zip';
}
