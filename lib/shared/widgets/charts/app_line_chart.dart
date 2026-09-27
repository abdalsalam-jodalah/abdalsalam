import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'chart_frame.dart';

class AppChartSeries {
  final List<double> points;
  final Color color;

  const AppChartSeries({required this.points, required this.color});
}

class AppLineChart extends StatelessWidget {
  static const double _lineWidth = 3;
  static const double _areaTopOpacity = 0.28;
  static const double _bottomAxisReservedSize = 32;
  static const double _leftAxisReservedSize = 48;

  final List<double> points;
  final Color? color;
  final double height;
  final String Function(double value)? formatValue;
  final List<AppChartSeries> extraSeries;
  final List<String>? axisLabels;
  final String Function(double value)? yAxisLabelBuilder;

  const AppLineChart({
    super.key,
    required this.points,
    this.color,
    this.height = ChartFrame.defaultHeight,
    this.formatValue,
    this.extraSeries = const <AppChartSeries>[],
    this.axisLabels,
    this.yAxisLabelBuilder,
  });

  LineChartBarData _seriesData(List<double> values, Color lineColor, {required bool showArea}) {
    return LineChartBarData(
      isCurved: true,
      preventCurveOverShooting: true,
      color: lineColor,
      barWidth: _lineWidth,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: showArea,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: _areaTopOpacity), lineColor.withValues(alpha: 0)],
        ),
      ),
      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final lineColor = color ?? theme.colorScheme.primary;
    final labels = axisLabels;
    final showAxes = labels != null || yAxisLabelBuilder != null;
    final axisLabelStyle = theme.textTheme.labelSmall?.copyWith(color: tokens.colors.muted);
    final hasSingleSeries = extraSeries.isEmpty;

    return ChartFrame(
      isEmpty: points.isEmpty && extraSeries.every((series) => series.points.isEmpty),
      height: height,
      child: LineChart(
        duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : AppMotion.slow,
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: !showAxes
              ? const FlTitlesData(show: false)
              : FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: labels != null,
                      reservedSize: _bottomAxisReservedSize,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (labels == null || index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: tokens.spacing.xs),
                          child: Text(labels[index], style: axisLabelStyle),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: yAxisLabelBuilder != null,
                      reservedSize: _leftAxisReservedSize,
                      getTitlesWidget: (value, meta) =>
                          Text(yAxisLabelBuilder?.call(value) ?? '', style: axisLabelStyle),
                    ),
                  ),
                ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    formatValue?.call(spot.y) ?? spot.y.toStringAsFixed(1),
                    theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onInverseSurface),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            _seriesData(points, lineColor, showArea: hasSingleSeries),
            for (final series in extraSeries) _seriesData(series.points, series.color, showArea: false),
          ],
        ),
      ),
    );
  }
}
