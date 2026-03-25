import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;

import 'app.dart';
import 'providers/app_providers.dart';
import 'shared/infrastructure/database_schema_initializer.dart';
import 'shared/infrastructure/logger_service.dart';
import 'shared/infrastructure/storage_gateway.dart';
import 'shared/services/app_lifecycle_logger.dart';

// ignore: unused_element
AppLifecycleLogger? _appLifecycleLogger;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  _appLifecycleLogger = AppLifecycleLogger(
    appStateManager: appStateManager,
    logger: LoggerService.forModule('AppLifecycle', moduleType: logic.ModuleType.service),
  )..start();

  runApp(
    ProviderScope(
      overrides: [
        appStateManagerProvider.overrideWithValue(appStateManager),
      ],
      child: const AbdalsalamApp(),
    ),
  );
}
