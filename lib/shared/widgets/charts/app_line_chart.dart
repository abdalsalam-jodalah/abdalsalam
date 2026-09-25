import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import 'chart_frame.dart';

class AppLineChart extends StatelessWidget {
  static const double _lineWidth = 3;
  static const double _areaTopOpacity = 0.28;

  final List<double> points;
  final Color? color;
  final double height;
  final String Function(double value)? formatValue;

  const AppLineChart({
    super.key,
    required this.points,
    this.color,
    this.height = ChartFrame.defaultHeight,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = color ?? theme.colorScheme.primary;
    return ChartFrame(
      isEmpty: points.isEmpty,
      height: height,
      child: LineChart(
        duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : AppMotion.slow,
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
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
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: lineColor,
              barWidth: _lineWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lineColor.withValues(alpha: _areaTopOpacity), lineColor.withValues(alpha: 0)],
                ),
              ),
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i])],
            ),
          ],
        ),
      ),
    );
  }
}
