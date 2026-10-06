import 'package:flutter/material.dart';

class DashboardGreetingIcon {
  static const int _morningStartHour = 5;
  static const int _afternoonStartHour = 12;
  static const int _eveningStartHour = 17;
  static const int _nightStartHour = 21;

  const DashboardGreetingIcon._();

  static IconData forTime(DateTime time) {
    final hour = time.hour;
    if (hour >= _nightStartHour || hour < _morningStartHour) return Icons.nightlight_round;
    if (hour >= _eveningStartHour) return Icons.wb_twilight_rounded;
    if (hour >= _afternoonStartHour) return Icons.wb_sunny_rounded;
    return Icons.coffee_rounded;
  }
}
