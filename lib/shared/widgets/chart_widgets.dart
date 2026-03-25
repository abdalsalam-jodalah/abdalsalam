import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> points;

  const TrendLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              spots: [
                for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DistributionPieChart extends StatelessWidget {
  final Map<String, double> values;

  const DistributionPieChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList(growable: false);
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.teal];

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            for (var i = 0; i < entries.length; i++)
              PieChartSectionData(
                value: entries[i].value,
                title: entries[i].key,
                color: colors[i % colors.length],
              ),
          ],
        ),
      ),
    );
  }
}

class ComparisonBarChart extends StatelessWidget {
  final List<double> values;

  const ComparisonBarChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [BarChartRodData(toY: values[i], color: Colors.indigo)],
              ),
          ],
        ),
      ),
    );
  }
}
