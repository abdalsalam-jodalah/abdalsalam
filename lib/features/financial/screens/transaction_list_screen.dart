import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class TransactionListScreen extends StatelessWidget {
  static const routeName = '/financial/transactions';

  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Transactions',
      description: 'Search and filter financial records by date, category, and tags.',
      icon: Icons.receipt_long_outlined,
      metrics: [
        SectionMetric(label: 'Records', value: '128'),
        SectionMetric(label: 'Today', value: '4'),
        SectionMetric(label: 'Categories', value: '11'),
        SectionMetric(label: 'Filtered', value: '18'),
      ],
      focusItems: ['Find large expenses', 'Filter by transport', 'Sort by amount'],
      initialActivities: ['Filter used: This month'],
      quickAddHint: 'Example: Salary +1200',
    );
  }
}
