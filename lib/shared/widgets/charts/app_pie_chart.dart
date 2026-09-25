import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme_tokens.dart';
import 'chart_frame.dart';
import 'chart_palette.dart';

class AppPieChart extends StatelessWidget {
  static const double _centerSpaceRadius = 44;
  static const double _sectionRadius = 36;
  static const double _sectionSpacing = 3;
  static const double _legendDotSize = 10;

  final Map<String, double> values;
  final double height;

  const AppPieChart({super.key, required this.values, this.height = ChartFrame.defaultHeight});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final palette = ChartPalette.of(context);
    final entries = values.entries.where((entry) => entry.value > 0).toList(growable: false);
    return ChartFrame(
      isEmpty: entries.isEmpty,
      height: height,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              swapAnimationDuration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : AppMotion.slow,
              PieChartData(
                centerSpaceRadius: _centerSpaceRadius,
                sectionsSpace: _sectionSpacing,
                sections: [
                  for (var i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: entries[i].value,
                      showTitle: false,
                      radius: _sectionRadius,
                      color: palette[i % palette.length],
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: tokens.spacing.lg),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: _legendDotSize,
                        height: _legendDotSize,
                        decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle),
                      ),
                      SizedBox(width: tokens.spacing.sm),
                      Text(entries[i].key, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
