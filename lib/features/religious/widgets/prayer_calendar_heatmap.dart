import 'package:flutter/material.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';

class PrayerCalendarHeatmap extends StatelessWidget {
  static const int _prayersPerDay = 5;
  static const int _daysShown = 30;
  static const int _daysPerWeek = 7;
  static const List<double> _legendLevels = <double>[0, 0.25, 0.5, 0.75, 1];
  static const double _legendCellSize = 12;

  final Map<DateTime, int> dailyCompletions;

  const PrayerCalendarHeatmap({super.key, required this.dailyCompletions});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final accent = AppModuleAccents.forModule('religious');
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day).subtract(const Duration(days: _daysShown - 1));

    final days = List<DateTime>.generate(_daysShown, (i) => startDay.add(Duration(days: i)));
    final leadingBlanks = startDay.weekday % _daysPerWeek;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prayer completion', style: theme.textTheme.titleMedium),
              Text('Last 30 days', style: theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted)),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          GridView.count(
            crossAxisCount: _daysPerWeek,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: tokens.spacing.xs,
            mainAxisSpacing: tokens.spacing.xs,
            children: [
              for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
              for (final day in days)
                Tooltip(
                  message: '${day.month}/${day.day}: ${dailyCompletions[day] ?? 0}/$_prayersPerDay',
                  child: _HeatCell(
                    intensity: ((dailyCompletions[day] ?? 0) / _prayersPerDay).clamp(0, 1).toDouble(),
                    color: accent,
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted)),
              SizedBox(width: tokens.spacing.xs),
              for (final level in _legendLevels)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.xs / 2),
                  child: _HeatCell(intensity: level, color: accent, size: _legendCellSize),
                ),
              SizedBox(width: tokens.spacing.xs),
              Text('More', style: theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  static const double _defaultSize = 16;
  static const double _minimumIntensityOpacity = 0.2;
  static const double _emptyOpacity = 0.5;

  final double intensity;
  final Color color;
  final double size;

  const _HeatCell({required this.intensity, required this.color, this.size = _defaultSize});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: intensity == 0
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: _emptyOpacity)
            : color.withValues(alpha: _minimumIntensityOpacity + (1 - _minimumIntensityOpacity) * intensity),
        borderRadius: tokens.radius.smallBorder,
      ),
    );
  }
}
