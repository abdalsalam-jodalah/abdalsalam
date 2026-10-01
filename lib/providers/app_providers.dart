import 'dart:async';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/bootstrap/startup_report.dart';
import '../core/errors/app_error.dart';
import '../core/result/result.dart';
import '../data/repositories/calendar/calendar_repository.dart';
import '../data/repositories/security/security_repository.dart';
import '../features/calendar/services/calendar_service.dart';
import '../features/security/services/security_service.dart';
import '../shared/infrastructure/database_schema_initializer.dart';
import '../shared/infrastructure/logger_service.dart';
import '../shared/infrastructure/storage_gateway.dart';
import '../shared/services/notification_service.dart';
import '../shared/services/analytics_engine.dart';
import '../shared/services/achievement_service.dart';
import '../shared/services/backup_attachment_bundler.dart';
import '../shared/services/auto_backup_service.dart';
import '../shared/services/backup_service.dart';
import '../shared/services/backup_status.dart';
import '../shared/services/backup_status_service.dart';
import '../shared/services/export_row_enricher.dart';
import '../shared/services/financial_export_enricher.dart';
import '../shared/services/module_export_service.dart';
import '../shared/services/module_table_registry.dart';
import '../shared/services/future_sync_service.dart';
import '../shared/services/settings_service.dart';
import '../shared/services/state_aware_service.dart';
import '../shared/services/sync_queue_service.dart';
import '../shared/services/reminder_service.dart';
import '../shared/services/attachment_storage_service.dart';
import '../shared/services/error_handler.dart';
import '../shared/services/user_error_message_mapper.dart';

final loggerProvider = Provider<LoggerService>((ref) {
  return LoggerService.forModule('App', moduleType: logic.ModuleType.service);
});

final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler(ref.watch(loggerProvider));
});

final userErrorMessageMapperProvider = Provider<UserErrorMessageMapper>((ref) {
  return const UserErrorMessageMapper();
});

final storageGatewayProvider = Provider<StorageGateway>((ref) {
  return StorageGateway.instance;
});

final corruptRecordCountProvider = StreamProvider<int>((ref) async* {
  final reporter = ref.watch(storageGatewayProvider).integrityReporter;
  yield reporter.corruptRecordCount;
  yield* reporter.corruptRecordCountChanges;
});

final appStateManagerProvider = Provider<logic.AppStateManager>((ref) {
  throw UnimplementedError('appStateManagerProvider must be overridden in main.dart');
});

final appStateInfoProvider = StreamProvider<logic.AppStateInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.stateStream;
});

final batteryInfoProvider = StreamProvider<logic.BatteryInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.batteryStream;
});

final storageInfoProvider = StreamProvider<logic.StorageInfo>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  return appState.storageStream;
});

final isOfflineProvider = Provider<bool>((ref) {
  final appState = ref.watch(appStateInfoProvider);
  return appState.maybeWhen(
    data: (state) => state.isOffline,
    orElse: () => false,
  );
});

final syncQueueProcessorProvider = Provider<SyncQueueConnectivityProcessor>((ref) {
  final appState = ref.watch(appStateManagerProvider);
  final logger = ref.watch(loggerProvider);
  final syncQueueService = ref.watch(syncQueueServiceProvider);
  final processor = SyncQueueConnectivityProcessor(appState, logger, syncQueueService);
  ref.onDispose(processor.dispose);
  return processor;
});

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final logger = ref.watch(loggerProvider);
  final storage = ref.watch(storageGatewayProvider);
  return SyncQueueService(storage, logger);
});

final stateAwareServiceProvider = Provider<StateAwareService>((ref) {
  return StateAwareService(
    appState: ref.watch(appStateManagerProvider),
    storage: ref.watch(storageGatewayProvider),
    logger: ref.watch(loggerProvider),
  );
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    storage: ref.watch(storageGatewayProvider),
    logger: ref.watch(loggerProvider),
    notifications: ref.watch(notificationServiceProvider),
    settings: ref.watch(settingsServiceProvider),
  );
});

final attachmentStorageServiceProvider = Provider<AttachmentStorageService>((ref) {
  return AttachmentStorageService(
    logger: ref.watch(loggerProvider),
    subDirectory: 'health_attachments',
  );
});

final foodAttachmentStorageServiceProvider = Provider<AttachmentStorageService>((ref) {
  return AttachmentStorageService(
    logger: ref.watch(loggerProvider),
    subDirectory: 'food_attachments',
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    plugin: FlutterLocalNotificationsPlugin(),
    logger: ref.watch(loggerProvider),
  );
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(
    ref.watch(storageGatewayProvider),
    LoggerService.forModule('CalendarRepository', moduleType: logic.ModuleType.repository),
  );
});

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepositoryImpl(
    ref.watch(storageGatewayProvider),
    LoggerService.forModule('SecurityRepository', moduleType: logic.ModuleType.repository),
  );
});

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService(
    ref.watch(calendarRepositoryProvider),
    LoggerService.forModule('CalendarService', moduleType: logic.ModuleType.service),
    reminders: ref.watch(reminderServiceProvider),
  );
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(
    ref.watch(securityRepositoryProvider),
    LoggerService.forModule('SecurityService', moduleType: logic.ModuleType.service),
    secureStorage: const FlutterSecureStorage(),
    localAuth: LocalAuthentication(),
    reminders: ref.watch(reminderServiceProvider),
  );
});

final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) {
  return AnalyticsEngine();
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(storageGatewayProvider));
});

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(settingsServiceProvider).getSettings();
});

/// The persisted sidebar order, loaded synchronously during app bootstrap
/// (before the first frame) and overridden in main.dart — so the sidebar
/// never flashes the default order while the async settings load resolves.
final appReloadProvider = Provider<VoidCallback>((ref) => () {});

final initialSidebarOrderProvider = Provider<List<String>?>((ref) => null);

final startupReportProvider = Provider<StartupReport>((ref) => const StartupReport());

final backupTablesProvider = Provider<List<String>>((ref) {
  return DatabaseSchemaInitializer.tables;
});

final backupAttachmentBundlerProvider = Provider<BackupAttachmentBundler>((ref) {
  return BackupAttachmentBundler(<AttachmentBinding>[
    AttachmentBinding(
      table: 'doctor_visits',
      field: 'attachmentPaths',
      isList: true,
      storage: ref.watch(attachmentStorageServiceProvider),
    ),
    AttachmentBinding(
      table: 'food_logs',
      field: 'imagePath',
      storage: ref.watch(foodAttachmentStorageServiceProvider),
    ),
  ]);
});

final backupStatusServiceProvider = Provider<BackupStatusService>((ref) {
  return BackupStatusService(ref.watch(storageGatewayProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(storageGatewayProvider),
    ref.watch(loggerProvider),
    attachmentBundler: ref.watch(backupAttachmentBundlerProvider),
    backupStatus: ref.watch(backupStatusServiceProvider),
  );
});

final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  return AutoBackupService(
    backups: ref.watch(backupServiceProvider),
    status: ref.watch(backupStatusServiceProvider),
    settings: ref.watch(settingsServiceProvider),
    logger: ref.watch(loggerProvider),
  );
});

final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) {
  return ref.watch(backupStatusServiceProvider).read();
});

final backupReminderDaysProvider = FutureProvider.autoDispose<int?>((ref) async {
  final settings = await ref.watch(settingsServiceProvider).getSettings();
  final configuredDays = settings[AutoBackupService.intervalDaysSettingKey];
  return ref.watch(backupStatusServiceProvider).exportReminderDaysOverdue(
        reminderDays: configuredDays is int ? configuredDays : AutoBackupService.defaultIntervalDays,
      );
});

final moduleExportServiceProvider = Provider<ModuleExportService>((ref) {
  return ModuleExportService(
    ref.watch(storageGatewayProvider),
    ref.watch(loggerProvider),
    enrichers: const <ExportRowEnricher>[FinancialExportEnricher()],
  );
});

final recordCountsByModuleProvider = FutureProvider.autoDispose<Map<DataModule, int>>((ref) {
  return ref.watch(moduleExportServiceProvider).countRecordsByModule();
});

final futureSyncServiceProvider = Provider<FutureSyncService>((ref) {
  return const FutureSyncService();
});

class SyncQueueConnectivityProcessor {
  final logic.AppStateManager _appStateManager;
  final LoggerService _logger;
  final SyncQueueService _syncQueueService;
  StreamSubscription<logic.AppStateInfo>? _subscription;
  StreamSubscription<logic.StorageInfo>? _storageSubscription;

  SyncQueueConnectivityProcessor(this._appStateManager, this._logger, this._syncQueueService) {
    _subscription = _appStateManager.stateStream.listen((state) {
      if (state.isOnline) {
        _logger.info('[SyncQueue] connectivity restored; queued operations can sync now');
        unawaited(_syncQueueService.processQueue(_keepQueuedUntilBackendExists).then((result) {
          if (result.isFailure) {
            _logger.warning('[SyncQueue] processing failed: ${result.error!.message}');
          }
        }));
      }
    });

    _storageSubscription = _appStateManager.storageStream.listen((info) {
      if (info.usagePercentage >= 90) {
        _logger.warning('[Storage] low storage warning usage=${info.usagePercentage.toStringAsFixed(1)}%');
      } else {
        _logger.debug('[Storage] usage=${info.usagePercentage.toStringAsFixed(1)}%');
      }
    });
  }

  Future<Result<void, AppError>> _keepQueuedUntilBackendExists(SyncQueueItem item) async {
    return Failure(ServiceError('No sync backend configured; ${item.operation} ${item.id} stays queued'));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _storageSubscription?.cancel();
  }
}
