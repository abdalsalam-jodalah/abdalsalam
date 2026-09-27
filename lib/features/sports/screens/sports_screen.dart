import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
import 'calendar_view_screen.dart';
import 'daily_log_screen.dart';
import 'exercise_library_screen.dart';
import 'sports_dashboard_screen.dart';
import 'weekly_schedule_screen.dart';

/// Tabbed hub for the sport module: Daily Log / Schedule / Library /
/// Dashboard / Calendar.
class SportsScreen extends StatelessWidget {
  static const routeName = '/sports';

  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScaffold(
      destinations: [
        ModuleHubDestination(
          label: 'Today',
          icon: Icons.fitness_center_outlined,
          selectedIcon: Icons.fitness_center,
          page: DailyLogScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Schedule',
          icon: Icons.calendar_view_week_outlined,
          selectedIcon: Icons.calendar_view_week,
          page: WeeklyScheduleScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Library',
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          page: ExerciseLibraryScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights,
          page: SportsDashboardScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          page: CalendarViewScreen(embedded: true),
        ),
      ],
    );
  }
}
