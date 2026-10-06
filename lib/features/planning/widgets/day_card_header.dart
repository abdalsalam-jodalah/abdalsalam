import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'day_highlight.dart';

class DayCardHeader extends StatelessWidget {
  static const String _todayLabel = 'Today';
  static const String _noTasksLabel = 'No tasks';
  static const double _badgeWidth = 52;
  static const double _badgeHeight = 56;
  static const double _progressHeight = 6;
  static const double _titleRowHeight = 26;

  final DateTime date;
  final DayHighlight highlight;
  final int completedCount;
  final int totalCount;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DayCardHeader({
    super.key,
    required this.date,
    required this.highlight,
    required this.completedCount,
    required this.totalCount,
    required this.onAdd,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAllDone = totalCount > 0 && completedCount == totalCount;
    return InkWell(
      onTap: onTap,
      borderRadius: tokens.radius.largeBorder,
      child: Padding(
        padding: EdgeInsets.fromLTRB(tokens.spacing.md, tokens.spacing.md, tokens.spacing.xs, tokens.spacing.md),
        child: Row(
          children: [
            _DateBadge(date: date, highlight: highlight, width: _badgeWidth, height: _badgeHeight),
            SizedBox(width: tokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _titleRowHeight,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            AppDateFormatter.weekdayFull(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: highlight.titleColor(colors),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (highlight.isToday) ...[
                          SizedBox(width: tokens.spacing.sm),
                          _TodayPill(label: _todayLabel, colors: colors),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    AppDateFormatter.shortDate(date),
                    style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  SizedBox(height: tokens.spacing.xs),
                  if (totalCount == 0)
                    Text(_noTasksLabel, style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant))
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: tokens.radius.pillBorder,
                            child: LinearProgressIndicator(
                              value: completedCount / totalCount,
                              minHeight: _progressHeight,
                              color: isAllDone ? colors.tertiary : colors.primary,
                              backgroundColor: colors.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        SizedBox(width: tokens.spacing.sm),
                        Text('$completedCount/$totalCount done', style: textTheme.labelMedium),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(tooltip: 'Add task', icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final DayHighlight highlight;
  final double width;
  final double height;

  const _DateBadge({required this.date, required this.highlight, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = highlight.badgeForeground(colors);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: highlight.badgeBackground(colors), borderRadius: tokens.radius.mediumBorder),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppDateFormatter.weekdayShort(date).toUpperCase(),
            style: textTheme.labelSmall?.copyWith(color: foreground, letterSpacing: 0.6),
          ),
          Text(
            AppDateFormatter.dayOfMonth(date),
            style: textTheme.titleLarge?.copyWith(color: foreground, fontWeight: FontWeight.w800, height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  final String label;
  final ColorScheme colors;

  const _TodayPill({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.primary, borderRadius: tokens.radius.pillBorder),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sm, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
