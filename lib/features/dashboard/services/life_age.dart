class LifeAge {
  static const int _minutesPerHour = 60;
  static const int _hoursPerDay = 24;

  final int years;
  final int days;
  final int hours;
  final int minutes;
  final int totalDays;
  final int totalHours;
  final int totalMinutes;

  const LifeAge({
    required this.years,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.totalDays,
    required this.totalHours,
    required this.totalMinutes,
  });

  factory LifeAge.between(DateTime birthDate, DateTime now) {
    final lived = now.difference(birthDate);
    var years = now.year - birthDate.year;
    if (_anniversary(birthDate, years).isAfter(now)) {
      years -= 1;
    }
    final sinceAnniversary = now.difference(_anniversary(birthDate, years));
    return LifeAge(
      years: years,
      days: sinceAnniversary.inDays,
      hours: sinceAnniversary.inHours % _hoursPerDay,
      minutes: sinceAnniversary.inMinutes % _minutesPerHour,
      totalDays: lived.inDays,
      totalHours: lived.inHours,
      totalMinutes: lived.inMinutes,
    );
  }

  static DateTime _anniversary(DateTime birthDate, int years) {
    return DateTime(birthDate.year + years, birthDate.month, birthDate.day, birthDate.hour, birthDate.minute);
  }
}
