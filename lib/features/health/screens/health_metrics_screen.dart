import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class HealthMetricsScreen extends StatelessWidget {
  static const routeName = '/health/metrics';

  const HealthMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Health Metrics',
      description: 'View trends for weight, blood pressure, and glucose.',
      icon: Icons.monitor_heart_outlined,
      metrics: [
        SectionMetric(label: 'Weight', value: '77.8kg'),
        SectionMetric(label: 'BP', value: '122/80'),
        SectionMetric(label: 'Glucose', value: '95'),
        SectionMetric(label: 'Trend', value: 'Stable'),
      ],
      focusItems: ['Log new metric', 'Review chart trend', 'Compare monthly average'],
      initialActivities: ['BP logged this morning'],
    );
  }
}
