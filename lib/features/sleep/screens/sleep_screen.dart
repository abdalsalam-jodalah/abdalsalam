import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
import 'sleep_home_screen.dart';
import 'sleep_logs_screen.dart';

/// Tabbed hub for the sleep module: Dashboard / Logs.
class SleepScreen extends StatelessWidget {
  static const routeName = '/sleep';

  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScaffold(
      destinations: [
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          page: SleepHomeScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Logs',
          icon: Icons.bedtime_outlined,
          selectedIcon: Icons.bedtime,
          page: SleepLogsScreen(embedded: true),
        ),
      ],
    );
  }
}
