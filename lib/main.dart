import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'data/repositories/health/health_repository.dart';
import 'data/repositories/health/medication_log_repository.dart';
import 'features/health/services/health_service.dart';
import 'features/health/services/medication_daily_rollover_service.dart';
import 'features/health/services/medication_service.dart';
import 'providers/app_providers.dart';
import 'shared/infrastructure/database_schema_initializer.dart';
import 'shared/infrastructure/logger_service.dart';
import 'shared/infrastructure/storage_gateway.dart';
import 'shared/services/app_lifecycle_logger.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/reminder_service.dart';
import 'shared/services/settings_service.dart';
import 'shared/services/wellness_reminder_rollover_service.dart';

// ignore: unused_element
AppLifecycleLogger? _appLifecycleLogger;
// ignore: unused_element
StreamSubscription<ReminderPayload>? _medicationMarkTakenSubscription;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapResult {
  final logic.AppStateManager appStateManager;
  final NotificationService notificationService;
  final ReminderService reminderService;
  final List<String>? initialSidebarOrder;

  const _BootstrapResult({
    required this.appStateManager,
    required this.notificationService,
    required this.reminderService,
    required this.initialSidebarOrder,
  });
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  late final Future<_BootstrapResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapResult> _bootstrap() async {
    await LoggerService.initialize();

    final appStateManager = logic.AppStateManagerImpl.create(
      config: const logic.AppStateConfig(
        enableConnectivity: true,
        enableDeviceInfo: true,
        enableBattery: true,
        enableStorage: true,
        enableNetworkType: true,
      ),
    );
    await appStateManager.initialize();

    await StorageGateway.instance.initialize();
    await DatabaseSchemaInitializer.initialize(StorageGateway.instance);

    final settingsService = SettingsService(StorageGateway.instance);
    final settings = await settingsService.getSettings();
    final initialSidebarOrder = (settings['sidebarOrder'] as List?)?.cast<String>();

    final notificationService = NotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
      logger: LoggerService.forModule('NotificationService', moduleType: logic.ModuleType.service),
    );
    final reminderService = ReminderService(
      storage: StorageGateway.instance,
      logger: LoggerService.forModule('ReminderService', moduleType: logic.ModuleType.service),
      notifications: notificationService,
      settings: settingsService,
    );
    await notificationService.initialize(
      onNotificationTap: reminderService.handleNotificationResponse,
    );
    await reminderService.rescheduleAll();

    final healthRepository = HealthRepositoryImpl(
      StorageGateway.instance,
      LoggerService.forModule('HealthRepository', moduleType: logic.ModuleType.repository),
    );
    final medicationLogRepository = MedicationLogRepositoryImpl(
      StorageGateway.instance,
      LoggerService.forModule('MedicationLogRepository', moduleType: logic.ModuleType.repository),
    );
    final medicationService = MedicationService(
      repository: healthRepository,
      logger: LoggerService.forModule('MedicationService', moduleType: logic.ModuleType.service),
      logRepository: medicationLogRepository,
    );
    final healthService = HealthService(
      healthRepository,
      LoggerService.forModule('HealthService', moduleType: logic.ModuleType.service),
      reminders: reminderService,
    );
    await MedicationDailyRolloverService(
      medicationService: medicationService,
      healthService: healthService,
      healthRepository: healthRepository,
      storage: StorageGateway.instance,
      logger: LoggerService.forModule('MedicationDailyRollover', moduleType: logic.ModuleType.service),
    ).runIfNeeded();
    await WellnessReminderRolloverService(
      reminderService: reminderService,
      storage: StorageGateway.instance,
      logger: LoggerService.forModule('WellnessReminderRollover', moduleType: logic.ModuleType.service),
    ).runIfNeeded();

    _medicationMarkTakenSubscription = reminderService.markTakenStream.listen((payload) async {
      final time = payload.metadata?['time'] as String?;
      if (time == null) return;
      await medicationService.markAsTaken(payload.targetId, DateTime.now(), time);
    });

    _appLifecycleLogger = AppLifecycleLogger(
      appStateManager: appStateManager,
      logger: LoggerService.forModule('AppLifecycle', moduleType: logic.ModuleType.service),
    )..start();

    return _BootstrapResult(
      appStateManager: appStateManager,
      notificationService: notificationService,
      reminderService: reminderService,
      initialSidebarOrder: initialSidebarOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to initialize app: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        final result = snapshot.data!;
        return ProviderScope(
          overrides: [
            appStateManagerProvider.overrideWithValue(result.appStateManager),
            notificationServiceProvider.overrideWithValue(result.notificationService),
            reminderServiceProvider.overrideWithValue(result.reminderService),
            initialSidebarOrderProvider.overrideWithValue(result.initialSidebarOrder),
          ],
          child: const AbdalsalamApp(),
        );
      },
    );
  }
}
