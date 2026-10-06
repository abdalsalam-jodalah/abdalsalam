class DayPlanningLayout {
  static const double wideBreakpoint = 840;
  static const double sidePanelWidth = 300;
  static const double minColumnWidth = 240;
  static const double scrollingColumnWidth = 270;
  static const double columnGap = 12;
  static const double singleColumnMaxWidth = 720;

  const DayPlanningLayout._();

  static bool isWide(double width) => width >= wideBreakpoint;
}
