import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Dashboard & Analytics',
      description: 'View trends and insights across all life management modules.',
      icon: Icons.insights_outlined,
      metrics: [
        SectionMetric(label: 'Tracked Modules', value: '9'),
        SectionMetric(label: 'Weekly Consistency', value: '74%'),
        SectionMetric(label: 'Best Progress', value: 'Religious'),
        SectionMetric(label: 'Attention Needed', value: 'Health'),
      ],
      focusItems: [
        'Review weekly summary',
        'Check module with lowest consistency',
        'Export monthly data snapshot',
      ],
      initialActivities: [
        'Weekly report generated',
        'Trend alert: spending increased 8%',
      ],
      quickAddHint: 'Example: tag insight for follow-up',
    );
  }
}
