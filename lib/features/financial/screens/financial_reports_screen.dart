import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class FinancialReportsScreen extends StatelessWidget {
  static const routeName = '/financial/reports';

  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Financial Reports',
      description: 'Income vs expenses, category trends, and report snapshots.',
      icon: Icons.pie_chart_outline,
      metrics: [
        SectionMetric(label: 'Savings Rate', value: '36%'),
        SectionMetric(label: 'Top Spend', value: 'Food'),
        SectionMetric(label: 'Avg Daily', value: r'$17'),
        SectionMetric(label: 'Report Range', value: '30d'),
      ],
      focusItems: ['Compare with last month', 'Export report', 'Review trend lines'],
      initialActivities: ['Monthly report generated'],
      quickAddHint: 'Example: Last 90 days',
    );
  }
}
