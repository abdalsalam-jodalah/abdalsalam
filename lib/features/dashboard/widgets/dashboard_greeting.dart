class DashboardGreeting {
  static const int _afternoonStartHour = 12;
  static const int _eveningStartHour = 17;
  static const int _nightStartHour = 22;
  static const int _morningStartHour = 5;

  const DashboardGreeting._();

  static String forTime(DateTime time) {
    final hour = time.hour;
    if (hour >= _nightStartHour || hour < _morningStartHour) {
      return 'Good night';
    }
    if (hour >= _eveningStartHour) {
      return 'Good evening';
    }
    if (hour >= _afternoonStartHour) {
      return 'Good afternoon';
    }
    return 'Good morning';
  }
}
