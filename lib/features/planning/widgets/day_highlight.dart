import 'package:flutter/material.dart';

enum DayHighlight {
  past,
  today,
  upcoming;

  static const double _todayTintOpacity = 0.35;

  factory DayHighlight.of(DateTime date, DateTime today) {
    if (date == today) return DayHighlight.today;
    return date.isBefore(today) ? DayHighlight.past : DayHighlight.upcoming;
  }

  bool get isToday => this == DayHighlight.today;

  Color badgeBackground(ColorScheme colors) => switch (this) {
    DayHighlight.today => colors.primary,
    DayHighlight.past => colors.surfaceContainerHighest,
    DayHighlight.upcoming => colors.secondaryContainer,
  };

  Color badgeForeground(ColorScheme colors) => switch (this) {
    DayHighlight.today => colors.onPrimary,
    DayHighlight.past => colors.onSurfaceVariant,
    DayHighlight.upcoming => colors.onSecondaryContainer,
  };

  Color titleColor(ColorScheme colors) => this == DayHighlight.past ? colors.onSurfaceVariant : colors.onSurface;

  Color cardColor(ColorScheme colors) =>
      isToday ? colors.primaryContainer.withValues(alpha: _todayTintOpacity) : colors.surfaceContainerLow;
}
