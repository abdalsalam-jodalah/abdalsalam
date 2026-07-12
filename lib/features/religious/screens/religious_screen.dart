import 'package:flutter/material.dart';

import 'athkar_screen.dart';
import 'prayer_logs_screen.dart';
import 'quran_reading_screen.dart';
import 'religious_history_screen.dart';
import 'religious_home_screen.dart';

/// Tabbed hub for the religious module: Dashboard / Prayers / Quran /
/// Athkar / History.
class ReligiousScreen extends StatefulWidget {
  static const routeName = '/religious';

  const ReligiousScreen({super.key});

  @override
  State<ReligiousScreen> createState() => _ReligiousScreenState();
}

class _ReligiousScreenState extends State<ReligiousScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    ReligiousHomeScreen(embedded: true),
    PrayerLogsScreen(embedded: true),
    QuranReadingScreen(embedded: true),
    AthkarScreen(embedded: true),
    ReligiousHistoryScreen(embedded: true),
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
            icon: Icon(Icons.mosque_outlined),
            selectedIcon: Icon(Icons.mosque),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Athkar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
