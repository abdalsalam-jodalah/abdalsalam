import 'package:equatable/equatable.dart';

import 'day_planning_view_mode.dart';

class DayPlanningRange extends Equatable {
  static const int defaultWeekStartDay = DateTime.saturday;
  static const int daysPerWeek = DateTime.daysPerWeek;
  static const int minCustomDays = 1;
  static const int maxCustomDays = 365;
  static const int defaultCustomDays = 3;

  final DateTime start;
  final DateTime end;

  const DayPlanningRange._(this.start, this.end);

  factory DayPlanningRange.of(
    DayPlanningViewMode mode,
    DateTime anchor, {
    int customDays = defaultCustomDays,
    int weekStartDay = defaultWeekStartDay,
  }) {
    final day = dateOnly(anchor);
    return switch (mode) {
      DayPlanningViewMode.day => DayPlanningRange._(day, day),
      DayPlanningViewMode.week => _weekOf(day, weekStartDay),
      DayPlanningViewMode.month => DayPlanningRange._(
        DateTime(day.year, day.month, 1),
        DateTime(day.year, day.month + 1, 0),
      ),
      DayPlanningViewMode.custom => DayPlanningRange._(
        day,
        DateTime(day.year, day.month, day.day + customDays.clamp(minCustomDays, maxCustomDays) - 1),
      ),
    };
  }

  static DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static int weekStartDayFromSetting(Object? value) {
    return switch (value) {
      'sunday' => DateTime.sunday,
      'monday' => DateTime.monday,
      _ => defaultWeekStartDay,
    };
  }

  static DateTime shiftAnchor(
    DayPlanningViewMode mode,
    DateTime anchor,
    int direction, {
    int customDays = defaultCustomDays,
  }) {
    final day = dateOnly(anchor);
    return switch (mode) {
      DayPlanningViewMode.day => DateTime(day.year, day.month, day.day + direction),
      DayPlanningViewMode.week => DateTime(day.year, day.month, day.day + direction * daysPerWeek),
      DayPlanningViewMode.month => DateTime(day.year, day.month + direction, 1),
      DayPlanningViewMode.custom => DateTime(
        day.year,
        day.month,
        day.day + direction * customDays.clamp(minCustomDays, maxCustomDays),
      ),
    };
  }

  static DayPlanningRange _weekOf(DateTime day, int weekStartDay) {
    final daysSinceWeekStart = (day.weekday - weekStartDay) % daysPerWeek;
    final weekStart = DateTime(day.year, day.month, day.day - daysSinceWeekStart);
    return DayPlanningRange._(weekStart, DateTime(weekStart.year, weekStart.month, weekStart.day + daysPerWeek - 1));
  }

  int get dayCount =>
      DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  List<DateTime> get days => List<DateTime>.generate(
    dayCount,
    (offset) => DateTime(start.year, start.month, start.day + offset),
    growable: false,
  );

  @override
  List<Object?> get props => [start, end];
}
