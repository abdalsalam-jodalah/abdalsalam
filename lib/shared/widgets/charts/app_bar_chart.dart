import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'chart_frame.dart';

class AppBarChart extends StatelessWidget {
  static const double _barWidth = 14;
  static const double _trackOpacity = 0.35;
  static const double _axisLabelReservedSize = 20;

  final List<double> values;
  final Color? color;
  final double height;
  final String Function(double value)? formatValue;
  final List<String>? axisLabels;

  const AppBarChart({
    super.key,
    required this.values,
    this.color,
    this.height = ChartFrame.defaultHeight,
    this.formatValue,
    this.axisLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final barColor = color ?? theme.colorScheme.primary;
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final labels = axisLabels;
    return ChartFrame(
      isEmpty: values.isEmpty,
      height: height,
      child: BarChart(
        swapAnimationDuration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : AppMotion.slow,
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: labels == null
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _axisLabelReservedSize,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[index],
                          style: theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted),
                        );
                      },
                    ),
                  ),
                ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                formatValue?.call(rod.toY) ?? rod.toY.toStringAsFixed(1),
                theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: barColor,
                    width: _barWidth,
                    borderRadius: tokens.radius.smallBorder,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: maxValue > 0,
                      toY: maxValue,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: _trackOpacity),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
