import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/app_shell_screen.dart';
import 'providers/app_providers.dart';

class AbdalsalamApp extends ConsumerStatefulWidget {
  const AbdalsalamApp({super.key});

  @override
  ConsumerState<AbdalsalamApp> createState() => _AbdalsalamAppState();
}

class _AbdalsalamAppState extends ConsumerState<AbdalsalamApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncQueueProcessorProvider);
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Abdalsalam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AppShellScreen(),
    );
  }
}
