import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class BudgetManagementScreen extends StatelessWidget {
  static const routeName = '/financial/budgets';

  const BudgetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Budget Management',
      description: 'Define category budgets and monitor thresholds.',
      icon: Icons.savings_outlined,
      metrics: [
        SectionMetric(label: 'Active Budgets', value: '3'),
        SectionMetric(label: 'Over Budget', value: '1'),
        SectionMetric(label: 'Threshold', value: '80%'),
        SectionMetric(label: 'Alerts', value: '2'),
      ],
      focusItems: ['Adjust limits', 'Review alerts', 'Create new budget'],
      initialActivities: ['Food budget raised to 350'],
      quickAddHint: 'Example: Transport 200 monthly',
    );
  }
}
