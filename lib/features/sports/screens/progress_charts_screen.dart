import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class ProgressChartsScreen extends StatelessWidget {
  static const routeName = '/sports/progress';

  const ProgressChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Progress Charts',
      description: 'Track load, reps, and frequency over time.',
      icon: Icons.show_chart,
      metrics: [
        SectionMetric(label: 'Volume Trend', value: '+8%'),
        SectionMetric(label: 'Weekly Avg', value: '3.5'),
        SectionMetric(label: 'Best Lift', value: '95kg'),
        SectionMetric(label: 'Consistency', value: '81%'),
      ],
      focusItems: ['Check PR chart', 'Compare this month', 'Review weak areas'],
      initialActivities: ['Deadlift PR updated'],
    );
  }
}
