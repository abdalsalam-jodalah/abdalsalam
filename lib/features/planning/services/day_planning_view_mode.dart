enum DayPlanningViewMode {
  day('Day'),
  week('Week'),
  month('Month'),
  custom('Custom');

  final String label;

  const DayPlanningViewMode(this.label);
}
