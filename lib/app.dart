import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/startup_status_banner.dart';
import 'core/router/app_router.dart';
import 'features/religious/providers/religious_tracking_providers.dart';
import 'core/theme/app_theme_builder.dart';
import 'core/theme/appearance.dart';
import 'features/dashboard/screens/app_shell_screen.dart';
import 'providers/app_providers.dart';
import 'shared/services/reminder_service.dart';
import 'shared/widgets/data_integrity_banner.dart';
import 'shared/widgets/dev_tools_overlay.dart';

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
    unawaited(_reminderTapSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appSettingsProvider).maybeWhen(
          data: Appearance.fromSettings,
          orElse: () => Appearance.defaults,
        );

    return MaterialApp(
      title: 'Abdalsalam',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildAppTheme(appearance, Brightness.light),
      darkTheme: buildAppTheme(appearance, Brightness.dark),
      themeMode: appearance.themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) => Column(
        children: [
          const StartupStatusBanner(),
          DataIntegrityBanner(navigatorKey: _navigatorKey),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
      home: kDebugMode
          ? DevToolsOverlay(child: const AppShellScreen())
          : const AppShellScreen(),
    );
  }
}
