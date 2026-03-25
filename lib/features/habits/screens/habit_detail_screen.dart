import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  static const routeName = '/habits/detail';

  const HabitDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Habit Detail',
      description: 'Track calendar completion and detailed streak metrics.',
      icon: Icons.calendar_today_outlined,
      metrics: [
        SectionMetric(label: 'Current Streak', value: '7'),
        SectionMetric(label: 'Best Streak', value: '21'),
        SectionMetric(label: 'This Month', value: '82%'),
        SectionMetric(label: 'Skips', value: '2'),
      ],
      focusItems: ['Mark complete', 'Add note', 'Review missed days'],
      initialActivities: ['Completed at 08:00'],
    );
  }
}
