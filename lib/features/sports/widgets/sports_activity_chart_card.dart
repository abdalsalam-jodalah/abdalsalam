import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../providers/sports_providers.dart';

class SportsActivityChartCard extends ConsumerWidget {
  static const double _chartHeight = 200;
  static const String _title = 'Activity';
  static const String _emptyTitle = 'No activity for this period';
  static const String _emptySubtitle = 'Log a session to see it charted here.';

  final DateRangeQuery range;

  const SportsActivityChartCard({super.key, required this.range});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsInRangeProvider(range));
    final accent = AppModuleAccents.forModule('sports');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: _title, padding: EdgeInsets.zero),
          AsyncSection(
            value: logsAsync,
            onRetry: () => ref.invalidate(logsInRangeProvider(range)),
            builder: (logs) {
              if (logs.isEmpty) {
                return const EmptyState(
                  title: _emptyTitle,
                  subtitle: _emptySubtitle,
                  icon: Icons.show_chart_rounded,
                  isCompact: true,
                );
              }
              final dayCount = range.end.difference(range.start).inDays + 1;
              final days = [for (var i = 0; i < dayCount; i++) range.start.add(Duration(days: i))];
              final countByDay = <int, int>{};
              for (final log in logs) {
                final dayIndex = log.date.difference(range.start).inDays;
                countByDay[dayIndex] = (countByDay[dayIndex] ?? 0) + 1;
              }
              final values = [for (var i = 0; i < dayCount; i++) (countByDay[i] ?? 0).toDouble()];
              final axisLabels = [for (final day in days) '${day.day}'];
              return AppBarChart(values: values, axisLabels: axisLabels, color: accent, height: _chartHeight);
            },
          ),
        ],
      ),
    );
  }
}
