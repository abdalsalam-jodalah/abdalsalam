import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class HealthScreen extends StatelessWidget {
  static const routeName = '/health';

  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Health Management',
      description: 'Track medications, supplements, checkups, and health measurements.',
      icon: Icons.health_and_safety_outlined,
      metrics: [
        SectionMetric(label: 'Meds Today', value: '2/3'),
        SectionMetric(label: 'Next Checkup', value: '12 Apr'),
        SectionMetric(label: 'Water Intake', value: '1.8L'),
        SectionMetric(label: 'Sleep Last Night', value: '7h 20m'),
      ],
      focusItems: [
        'Take evening medication',
        'Log blood pressure',
        'Schedule vitamin refill',
      ],
      initialActivities: [
        'Vitamin D taken at 08:30',
        'Weight logged: 77.8 kg',
      ],
      quickAddHint: 'Example: BP 122/80',
    );
  }
}
