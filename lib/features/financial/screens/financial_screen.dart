import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class FinancialScreen extends StatelessWidget {
  static const routeName = '/financial';

  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Financial Management',
      description: 'Track expenses, income, budgets, and monthly cash flow.',
      icon: Icons.account_balance_wallet_outlined,
      metrics: [
        SectionMetric(label: 'This Month Spent', value: r'$420'),
        SectionMetric(label: 'This Month Income', value: r'$1,150'),
        SectionMetric(label: 'Active Budgets', value: '3'),
        SectionMetric(label: 'Top Category', value: 'Food'),
      ],
      focusItems: [
        'Add today expenses',
        'Review budget overages',
        'Log one income item',
      ],
      initialActivities: [
        'Coffee expense added - \$4.50',
        'Budget alert: Transport at 82%',
      ],
      quickAddHint: 'Example: Dinner \$18',
    );
  }
}
