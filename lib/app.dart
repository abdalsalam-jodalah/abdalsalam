import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/screens/app_shell_screen.dart';
import 'providers/app_providers.dart';

class AbdalsalamApp extends ConsumerWidget {
  const AbdalsalamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncQueueProcessorProvider);

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
