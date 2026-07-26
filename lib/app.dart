import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'features/religious/providers/religious_tracking_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/app_shell_screen.dart';
import 'providers/app_providers.dart';
import 'shared/services/reminder_service.dart';
import 'shared/widgets/dev_tools_overlay.dart';

ThemeMode _themeModeFromSetting(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class AbdalsalamApp extends ConsumerStatefulWidget {
  const AbdalsalamApp({super.key});

  @override
  ConsumerState<AbdalsalamApp> createState() => _AbdalsalamAppState();
}

class _AbdalsalamAppState extends ConsumerState<AbdalsalamApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<ReminderPayload>? _reminderTapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncQueueProcessorProvider);
      ref.read(religiousSyncSchedulerProvider).start();
      final reminders = ref.read(reminderServiceProvider);
      _reminderTapSubscription = reminders.tapStream.listen((payload) {
        final route = reminders.routeForPayload(payload);
        if (route != null) {
          _navigatorKey.currentState?.pushNamed(route);
        }
      });
    });
  }

  @override
  void dispose() {
    _reminderTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final themeMode = appSettings.maybeWhen(
      data: (settings) => _themeModeFromSetting(settings['themeMode'] as String?),
      orElse: () => ThemeMode.system,
    );

    return MaterialApp(
      title: 'Abdalsalam',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: kDebugMode
          ? DevToolsOverlay(child: const AppShellScreen())
          : const AppShellScreen(),
    );
  }
}
