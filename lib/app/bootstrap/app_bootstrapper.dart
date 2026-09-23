import 'dart:async';

import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../core/errors/app_error.dart';
import '../../data/repositories/health/health_repository.dart';
import '../../data/repositories/health/medication_log_repository.dart';
import '../../features/health/services/health_service.dart';
import '../../features/health/services/medication_daily_rollover_service.dart';
import '../../features/health/services/medication_service.dart';
import '../../shared/infrastructure/database_schema_initializer.dart';
import '../../shared/infrastructure/logger_service.dart';
import '../../shared/infrastructure/storage_gateway.dart';
import '../../shared/services/app_lifecycle_logger.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/reminder_service.dart';
import '../../shared/services/settings_service.dart';
import '../../shared/services/wellness_reminder_rollover_service.dart';
import 'app_bootstrap_result.dart';
import 'bootstrap_step.dart';
import 'bootstrap_step_runner.dart';

class AppBootstrapper {
  static const String _sidebarOrderSetting = 'sidebarOrder';
  static const String _medicationTimeMetadataKey = 'time';

  final StorageGateway _storage = StorageGateway.instance;
  final BootstrapStepRunner _runner = BootstrapStepRunner(
    loggerFactory: () => LoggerService.forModule('Bootstrap', moduleType: logic.ModuleType.service),
  );

  StreamSubscription<ReminderPayload>? _medicationMarkTakenSubscription;
  AppLifecycleLogger? _appLifecycleLogger;

  Future<AppBootstrapResult> bootstrap() async {
    await _runner.runAll(<BootstrapStep>[
      BootstrapStep.critical('Database engine', () async {
        if (kIsWeb) {
          databaseFactory = databaseFactoryFfiWeb;
        }
      }),
      BootstrapStep.critical('Logging', LoggerService.initialize),
      BootstrapStep.critical('Storage', _storage.initialize),
      BootstrapStep.critical('Database schema', () => DatabaseSchemaInitializer.initialize(_storage)),
    ]);

    final appStateManager = logic.AppStateManagerImpl.create(
      config: const logic.AppStateConfig(
        enableConnectivity: true,
        enableDeviceInfo: true,
        enableBattery: true,
        enableStorage: true,
        enableNetworkType: true,
      ),
    );
    final settingsService = SettingsService(_storage);
    final notificationService = NotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
      logger: LoggerService.forModule('NotificationService', moduleType: logic.ModuleType.service),
    );
    final reminderService = ReminderService(
      storage: _storage,
      logger: LoggerService.forModule('ReminderService', moduleType: logic.ModuleType.service),
      notifications: notificationService,
      settings: settingsService,
    );
    final healthRepository = HealthRepositoryImpl(
      _storage,
      LoggerService.forModule('HealthRepository', moduleType: logic.ModuleType.repository),
    );
    final medicationService = MedicationService(
      repository: healthRepository,
      logger: LoggerService.forModule('MedicationService', moduleType: logic.ModuleType.service),
      logRepository: MedicationLogRepositoryImpl(
        _storage,
        LoggerService.forModule('MedicationLogRepository', moduleType: logic.ModuleType.repository),
      ),
    );
    final healthService = HealthService(
      healthRepository,
      LoggerService.forModule('HealthService', moduleType: logic.ModuleType.service),
      reminders: reminderService,
    );

    List<String>? initialSidebarOrder;

    final startupReport = await _runner.runAll(<BootstrapStep>[
      BootstrapStep.optional('Device status', appStateManager.initialize),
      BootstrapStep.optional('Settings', () async {
        final settings = await settingsService.getSettings();
        initialSidebarOrder = _readSidebarOrder(settings[_sidebarOrderSetting]);
      }),
      BootstrapStep.optional('Notifications and reminders', () async {
        final initialization = await notificationService.initialize(
          onNotificationTap: reminderService.handleNotificationResponse,
        );
        initialization.getOrThrow();
        final summary = (await reminderService.rescheduleAll()).getOrThrow();
        if (summary.hasFailures) {
          throw ServiceError('${summary.failedCount} reminders could not be rescheduled');
        }
      }),
      BootstrapStep.optional(
        'Medication daily rollover',
        () async => (await MedicationDailyRolloverService(
          medicationService: medicationService,
          healthService: healthService,
          healthRepository: healthRepository,
          storage: _storage,
          logger: LoggerService.forModule('MedicationDailyRollover', moduleType: logic.ModuleType.service),
        ).runIfNeeded()).getOrThrow(),
      ),
      BootstrapStep.optional(
        'Wellness reminder rollover',
        () async => (await WellnessReminderRolloverService(
          reminderService: reminderService,
          storage: _storage,
          logger: LoggerService.forModule('WellnessReminderRollover', moduleType: logic.ModuleType.service),
        ).runIfNeeded()).getOrThrow(),
      ),
      BootstrapStep.optional('Medication reminder actions', () async {
        _listenForMedicationTaken(reminderService, medicationService);
      }),
      BootstrapStep.optional('Lifecycle logging', () async {
        _appLifecycleLogger = AppLifecycleLogger(
          appStateManager: appStateManager,
          logger: LoggerService.forModule('AppLifecycle', moduleType: logic.ModuleType.service),
        )..start();
      }),
    ]);

    return AppBootstrapResult(
      appStateManager: appStateManager,
      notificationService: notificationService,
      reminderService: reminderService,
      initialSidebarOrder: initialSidebarOrder,
      startupReport: startupReport,
    );
  }

  Future<void> dispose() async {
    await _medicationMarkTakenSubscription?.cancel();
    await _appLifecycleLogger?.stop();
  }

  List<String>? _readSidebarOrder(Object? value) {
    if (value is! List) {
      return null;
    }
    return value.whereType<String>().toList(growable: false);
  }

  void _listenForMedicationTaken(ReminderService reminderService, MedicationService medicationService) {
    final logger = LoggerService.forModule('MedicationReminderActions', moduleType: logic.ModuleType.service);
    _medicationMarkTakenSubscription = reminderService.markTakenStream.listen(
      (payload) => unawaited(_markMedicationTaken(payload, medicationService, logger)),
      onError: (Object error, StackTrace stackTrace) {
        logger.error('Medication reminder action stream failed', error: error, stackTrace: stackTrace);
      },
    );
  }

  Future<void> _markMedicationTaken(
    ReminderPayload payload,
    MedicationService medicationService,
    LoggerService logger,
  ) async {
    final time = payload.metadata?[_medicationTimeMetadataKey];
    if (time is! String) {
      logger.warning('Medication reminder ${payload.targetId} has no dose time; ignoring mark-taken action');
      return;
    }
    try {
      final result = await medicationService.markAsTaken(payload.targetId, DateTime.now(), time);
      if (result.isFailure) {
        logger.error('Marking medication ${payload.targetId} as taken failed', error: result.error);
      }
    } catch (error, stackTrace) {
      logger.error('Marking medication ${payload.targetId} as taken threw', error: error, stackTrace: stackTrace);
    }
  }
}
