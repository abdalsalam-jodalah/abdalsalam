import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class MedicationListScreen extends StatelessWidget {
  static const routeName = '/health/medications';

  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Medication List',
      description: 'Manage medications and schedule details.',
      icon: Icons.medication_outlined,
      metrics: [
        SectionMetric(label: 'Active', value: '4'),
        SectionMetric(label: 'Paused', value: '1'),
        SectionMetric(label: 'Refills Soon', value: '2'),
        SectionMetric(label: 'Reminders', value: '10'),
      ],
      focusItems: ['Check schedules', 'Update dosage', 'Mark adherence'],
      initialActivities: ['Vitamin D marked taken'],
    );
  }
}
