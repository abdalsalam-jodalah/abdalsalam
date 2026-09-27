import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
import 'food_home_screen.dart';
import 'food_logs_screen.dart';

/// Tabbed hub for the food module: Dashboard / Logs.
class FoodScreen extends StatelessWidget {
  static const routeName = '/food';

  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScaffold(
      destinations: [
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          page: FoodHomeScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Logs',
          icon: Icons.restaurant_outlined,
          selectedIcon: Icons.restaurant,
          page: FoodLogsScreen(embedded: true),
        ),
      ],
    );
  }
}
