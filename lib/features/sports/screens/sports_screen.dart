import 'package:flutter/material.dart';

import 'calendar_view_screen.dart';
import 'daily_log_screen.dart';
import 'exercise_library_screen.dart';
import 'sports_dashboard_screen.dart';
import 'weekly_schedule_screen.dart';

/// Tabbed hub for the sport module: Daily Log / Schedule / Library /
/// Dashboard / Calendar.
class SportsScreen extends StatefulWidget {
  static const routeName = '/sports';

  const SportsScreen({super.key});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    DailyLogScreen(embedded: true),
    WeeklyScheduleScreen(embedded: true),
    ExerciseLibraryScreen(embedded: true),
    SportsDashboardScreen(embedded: true),
    CalendarViewScreen(embedded: true),
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
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
