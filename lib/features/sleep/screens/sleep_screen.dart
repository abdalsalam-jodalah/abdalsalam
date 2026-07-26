import 'package:flutter/material.dart';

import 'sleep_home_screen.dart';
import 'sleep_logs_screen.dart';

/// Tabbed hub for the sleep module: Dashboard / Logs.
class SleepScreen extends StatefulWidget {
  static const routeName = '/sleep';

  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    SleepHomeScreen(embedded: true),
    SleepLogsScreen(embedded: true),
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
            icon: Icon(Icons.bedtime_outlined),
            selectedIcon: Icon(Icons.bedtime),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}
