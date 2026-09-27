import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
import 'blood_tests_screen.dart';
import 'doctor_visits_screen.dart';
import 'health_home_screen.dart';
import 'health_metrics_screen.dart';
import 'medication_list_screen.dart';

/// Tabbed hub for the health module: Dashboard / Medications / Metrics /
/// Blood Tests / Doctor Visits.
class HealthScreen extends StatelessWidget {
  static const routeName = '/health';

  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScaffold(
      destinations: [
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          page: HealthHomeScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Medications',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication,
          page: MedicationListScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Metrics',
          icon: Icons.monitor_heart_outlined,
          selectedIcon: Icons.monitor_heart,
          page: HealthMetricsScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Blood Tests',
          icon: Icons.science_outlined,
          selectedIcon: Icons.science,
          page: BloodTestsScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Visits',
          icon: Icons.medical_services_outlined,
          selectedIcon: Icons.medical_services,
          page: DoctorVisitsScreen(embedded: true),
        ),
      ],
    );
  }
}
