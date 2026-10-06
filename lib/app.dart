import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/startup_status_banner.dart';
import 'core/router/app_router.dart';
import 'features/financial/providers/financial_providers.dart';
import 'features/religious/providers/athkar_providers.dart';
import 'features/religious/providers/prayer_providers.dart';
import 'features/religious/providers/religious_tracking_providers.dart';
import 'core/theme/app_theme_builder.dart';
import 'features/dashboard/screens/app_shell_screen.dart';
import 'providers/app_providers.dart';
import 'providers/appearance_controller.dart';
import 'shared/services/reminder_service.dart';
import 'shared/widgets/backup_reminder_banner.dart';
import 'shared/widgets/data_integrity_banner.dart';
import 'shared/widgets/dev_tools_overlay.dart';

class AbdalsalamApp extends ConsumerStatefulWidget {
  const AbdalsalamApp({super.key});

  @override
  ConsumerState<AbdalsalamApp> createState() => _AbdalsalamAppState();
}

class _AbdalsalamAppState extends ConsumerState<AbdalsalamApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<ReminderPayload>? _reminderTapSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runAutoBackupIfDue());
      ref.read(syncQueueProcessorProvider);
      ref.read(religiousSyncSchedulerProvider).start();
      ref.read(financialStartupTasksProvider);
      unawaited(ref.read(athkarServiceProvider).scheduleSuggestionReminders(userId: demoUserId));
      final reminders = ref.read(reminderServiceProvider);
      _reminderTapSubscription = reminders.tapStream.listen((payload) async {
        final route = reminders.routeForPayload(payload);
        if (route != null) {
          await _navigatorKey.currentState?.pushNamed(route);
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_reminderTapSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_runAutoBackupIfDue());
      ref.invalidate(backupReminderDaysProvider);
    }
  }

  Future<void> _runAutoBackupIfDue() async {
    final result = await ref.read(autoBackupServiceProvider).runIfDue();
    if (mounted && result.isSuccess && result.data == true) {
      ref.invalidate(backupStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);

    return MaterialApp(
      title: 'Abdalsalam',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildAppTheme(appearance, Brightness.light),
      darkTheme: buildAppTheme(appearance, Brightness.dark),
      themeMode: appearance.themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final brightness = switch (appearance.themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(mediaQuery.textScaler.scale(1) * appearance.textScale),
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: _systemUiOverlayStyleFor(brightness),
            child: Column(
              children: [
                const StartupStatusBanner(),
                DataIntegrityBanner(navigatorKey: _navigatorKey),
                BackupReminderBanner(navigatorKey: _navigatorKey),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          ),
        );
      },
      home: kDebugMode
          ? DevToolsOverlay(child: const AppShellScreen())
          : const AppShellScreen(),
    );
  }

  SystemUiOverlayStyle _systemUiOverlayStyleFor(Brightness brightness) {
    final iconBrightness = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: brightness,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
