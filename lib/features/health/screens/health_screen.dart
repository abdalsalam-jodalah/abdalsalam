import 'package:flutter/material.dart';

import 'blood_tests_screen.dart';
import 'doctor_visits_screen.dart';
import 'health_home_screen.dart';
import 'health_metrics_screen.dart';
import 'medication_list_screen.dart';

/// Tabbed hub for the health module: Dashboard / Medications / Metrics /
/// Blood Tests / Doctor Visits.
class HealthScreen extends StatefulWidget {
  static const routeName = '/health';

  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    HealthHomeScreen(embedded: true),
    MedicationListScreen(embedded: true),
    HealthMetricsScreen(embedded: true),
    BloodTestsScreen(embedded: true),
    DoctorVisitsScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medications',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Metrics',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Blood Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Visits',
          ),
        ],
      ),
    );
  }
}
