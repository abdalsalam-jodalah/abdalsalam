import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../providers/app_providers.dart';
import '../error_handling/app_provider_observer.dart';
import 'app_bootstrap_result.dart';
import 'app_bootstrapper.dart';
import 'startup_recovery_screen.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  final AppBootstrapper _bootstrapper = AppBootstrapper();
  late Future<AppBootstrapResult> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrapper.bootstrap();
  }

  @override
  void dispose() {
    _bootstrapper.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() => _bootstrapFuture = _bootstrapper.bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBootstrapResult>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final result = snapshot.data;
        if (snapshot.hasError || result == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: StartupRecoveryScreen(
              error: snapshot.error ?? StateError('Startup produced no result'),
              stackTrace: snapshot.stackTrace,
              onRetry: _retry,
            ),
          );
        }

        return ProviderScope(
          observers: const [AppProviderObserver()],
          overrides: [
            appStateManagerProvider.overrideWithValue(result.appStateManager),
            notificationServiceProvider.overrideWithValue(result.notificationService),
            reminderServiceProvider.overrideWithValue(result.reminderService),
            initialSidebarOrderProvider.overrideWithValue(result.initialSidebarOrder),
            startupReportProvider.overrideWithValue(result.startupReport),
          ],
          child: const AbdalsalamApp(),
        );
      },
    );
  }
}
