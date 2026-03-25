import 'package:flutter/material.dart';

import '../../features/religious/screens/prayer_logs_screen.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case PrayerLogsScreen.routeName:
        return MaterialPageRoute<void>(
          builder: (_) => const PrayerLogsScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
