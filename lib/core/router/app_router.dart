import 'package:flutter/material.dart';

import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/financial/screens/financial_screen.dart';
import '../../features/habits/screens/habits_screen.dart';
import '../../features/health/screens/health_screen.dart';
import '../../features/notes/screens/notes_screen.dart';
import '../../features/religious/screens/prayer_logs_screen.dart';
import '../../features/religious/screens/quran_progress_screen.dart';
import '../../features/security/screens/security_screen.dart';
import '../../features/sports/screens/sports_screen.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PrayerLogsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PrayerLogsScreen(),
          settings: settings,
        );
      case QuranProgressScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const QuranProgressScreen(),
          settings: settings,
        );
      case FinancialScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const FinancialScreen(),
          settings: settings,
        );
      case HabitsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HabitsScreen(),
          settings: settings,
        );
      case SportsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SportsScreen(),
          settings: settings,
        );
      case HealthScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const HealthScreen(),
          settings: settings,
        );
      case NotesScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const NotesScreen(),
          settings: settings,
        );
      case CalendarScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const CalendarScreen(),
          settings: settings,
        );
      case SecurityScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const SecurityScreen(),
          settings: settings,
        );
      case AnalyticsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const AnalyticsScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
