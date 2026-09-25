import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class MonthHeatmap extends StatelessWidget {
  static const int _daysPerWeek = 7;
  static const double _emptyOpacity = 0.35;
  static const double _minimumIntensityOpacity = 0.25;
  static const List<String> _weekdayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final DateTime month;
  final double Function(DateTime day) intensityForDay;
  final ValueChanged<DateTime>? onDayTap;
  final Color? color;

  const MonthHeatmap({
    super.key,
    required this.month,
    required this.intensityForDay,
    this.onDayTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - DateTime.monday;
    final today = DateUtils.dateOnly(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted)),
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spacing.xs),
        GridView.count(
          crossAxisCount: _daysPerWeek,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: tokens.spacing.xs,
          crossAxisSpacing: tokens.spacing.xs,
          children: [
            for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
            for (var day = 1; day <= daysInMonth; day++)
              _HeatmapDay(
                date: DateTime(month.year, month.month, day),
                intensity: intensityForDay(DateTime(month.year, month.month, day)).clamp(0.0, 1.0),
                accent: accent,
                isToday: DateTime(month.year, month.month, day) == today,
                onTap: onDayTap,
              ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapDay extends StatelessWidget {
  final DateTime date;
  final double intensity;
  final Color accent;
  final bool isToday;
  final ValueChanged<DateTime>? onTap;

  const _HeatmapDay({
    required this.date,
    required this.intensity,
    required this.accent,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final background = intensity == 0
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: MonthHeatmap._emptyOpacity)
        : accent.withValues(
            alpha: MonthHeatmap._minimumIntensityOpacity + intensity * (1 - MonthHeatmap._minimumIntensityOpacity),
          );
    final foreground = intensity > 0.5 ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    return InkWell(
      borderRadius: tokens.radius.smallBorder,
      onTap: onTap == null ? null : () => onTap!(date),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: tokens.radius.smallBorder,
          border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text('${date.day}', style: theme.textTheme.labelSmall?.copyWith(color: foreground)),
      ),
    );
  }
}
