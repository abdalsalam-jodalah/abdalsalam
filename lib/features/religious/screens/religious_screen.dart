import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/module_hub_destination.dart';
import '../../../shared/widgets/ui/module_hub_scaffold.dart';
import 'athkar_screen.dart';
import 'prayer_logs_screen.dart';
import 'quran_reading_screen.dart';
import 'religious_history_screen.dart';
import 'religious_home_screen.dart';

/// Tabbed hub for the religious module: Dashboard / Prayers / Quran /
/// Athkar / History.
class ReligiousScreen extends StatelessWidget {
  static const routeName = '/religious';

  const ReligiousScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleHubScaffold(
      destinations: [
        ModuleHubDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          page: ReligiousHomeScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Prayers',
          icon: Icons.mosque_outlined,
          selectedIcon: Icons.mosque,
          page: PrayerLogsScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Quran',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          page: QuranReadingScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'Athkar',
          icon: Icons.favorite_outline,
          selectedIcon: Icons.favorite,
          page: AthkarScreen(embedded: true),
        ),
        ModuleHubDestination(
          label: 'History',
          icon: Icons.history,
          selectedIcon: Icons.history,
          page: ReligiousHistoryScreen(embedded: true),
        ),
      ],
    );
  }
}
