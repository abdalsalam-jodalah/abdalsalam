class ShellSidebarMetrics {
  const ShellSidebarMetrics._();

  static const double iconsWidth = 88;
  static const double expandedWidth = 264;

  static double expandProgressFor(double visibleWidth) {
    final progress = (visibleWidth - iconsWidth) / (expandedWidth - iconsWidth);
    return progress.clamp(0.0, 1.0);
  }
}
