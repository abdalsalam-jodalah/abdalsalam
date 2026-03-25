import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class BloodTestsScreen extends StatelessWidget {
  static const routeName = '/health/blood-tests';

  const BloodTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Blood Tests',
      description: 'Track schedules, outcomes, and follow-up dates.',
      icon: Icons.science_outlined,
      metrics: [
        SectionMetric(label: 'Scheduled', value: '2'),
        SectionMetric(label: 'Completed', value: '7'),
        SectionMetric(label: 'Next Test', value: '12 Apr'),
        SectionMetric(label: 'Facilities', value: '3'),
      ],
      focusItems: ['Schedule panel test', 'Add result', 'Set next test date'],
      initialActivities: ['CBC test completed'],
    );
  }
}
