import 'package:flutter/material.dart';

import '../widgets/settings_hub_tile.dart';
import 'calendar_settings_screen.dart';
import 'dashboard_settings_screen.dart';
import 'financial_settings_screen.dart';
import 'food_settings_screen.dart';
import 'general_settings_screen.dart';
import 'habits_settings_screen.dart';
import 'health_settings_screen.dart';
import 'medications_settings_screen.dart';
import 'notes_settings_screen.dart';
import 'planning_settings_screen.dart';
import 'religious_settings_screen.dart';
import 'security_settings_screen.dart';
import 'sleep_settings_screen.dart';
import 'sports_settings_screen.dart';

class _SettingsHubEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;

  const _SettingsHubEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.routeName,
  });
}

const _hubEntries = <_SettingsHubEntry>[
  _SettingsHubEntry(
    icon: Icons.tune,
    title: 'General',
    subtitle: 'Theme, language, notifications, backup',
    routeName: GeneralSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.mosque_outlined,
    title: 'Religious',
    subtitle: 'Prayer times, method, reminders',
    routeName: ReligiousSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Financial',
    subtitle: 'Currency, budgets, categories',
    routeName: FinancialSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.repeat_rounded,
    title: 'Habits',
    subtitle: 'Reminders, streak goals',
    routeName: HabitsSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.flag_outlined,
    title: 'Planning',
    subtitle: 'Life & day planning',
    routeName: PlanningSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.fitness_center,
    title: 'Sports',
    subtitle: 'Units, workout goals',
    routeName: SportsSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.health_and_safety_outlined,
    title: 'Health',
    subtitle: 'Blood tests, metric units',
    routeName: HealthSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.bedtime_outlined,
    title: 'Sleep',
    subtitle: 'Sleep goal, reminders',
    routeName: SleepSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.restaurant_outlined,
    title: 'Food',
    subtitle: 'Calorie and protein targets',
    routeName: FoodSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.medication_outlined,
    title: 'Medications',
    subtitle: 'Refill reminders',
    routeName: MedicationsSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.sticky_note_2_outlined,
    title: 'Notes',
    subtitle: 'Defaults, categories',
    routeName: NotesSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.calendar_month_outlined,
    title: 'Calendar',
    subtitle: 'Reminders, Google sync',
    routeName: CalendarSettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.lock_outline,
    title: 'Security',
    subtitle: 'Vault lock, password policy',
    routeName: SecuritySettingsScreen.routeName,
  ),
  _SettingsHubEntry(
    icon: Icons.insights_outlined,
    title: 'Dashboard & Analytics',
    subtitle: 'Card visibility, order, sidebar order',
    routeName: DashboardSettingsScreen.routeName,
  ),
];

class SettingsHubScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView.builder(
        itemCount: _hubEntries.length,
        itemBuilder: (context, index) {
          final entry = _hubEntries[index];
          return SettingsHubTile(
            icon: entry.icon,
            title: entry.title,
            subtitle: entry.subtitle,
            onTap: () => Navigator.of(context).pushNamed(entry.routeName),
          );
        },
      ),
    );
  }
}
