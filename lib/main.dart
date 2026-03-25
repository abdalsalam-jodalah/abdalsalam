import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'providers/app_providers.dart';
import 'shared/infrastructure/database_schema_initializer.dart';
import 'shared/infrastructure/logger_service.dart';
import 'shared/infrastructure/storage_gateway.dart';
import 'shared/services/app_lifecycle_logger.dart';
import 'shared/services/notification_service.dart';

// ignore: unused_element
AppLifecycleLogger? _appLifecycleLogger;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapResult {
  final logic.AppStateManager appStateManager;

  const _BootstrapResult({required this.appStateManager});
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

    await NotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
      logger: LoggerService.forModule('NotificationService', moduleType: logic.ModuleType.service),
    ).initialize();

    _appLifecycleLogger = AppLifecycleLogger(
      appStateManager: appStateManager,
      logger: LoggerService.forModule('AppLifecycle', moduleType: logic.ModuleType.service),
    )..start();

    return _BootstrapResult(appStateManager: appStateManager);
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

        final appStateManager = snapshot.data!.appStateManager;
        return ProviderScope(
          overrides: [
            appStateManagerProvider.overrideWithValue(appStateManager),
          ],
          child: const AbdalsalamApp(),
        );
      },
    );
  }
}
