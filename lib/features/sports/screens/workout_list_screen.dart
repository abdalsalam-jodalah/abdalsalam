import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class WorkoutListScreen extends StatelessWidget {
  static const routeName = '/sports/workouts';

  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Workout List',
      description: 'Search, filter, and review all logged sessions.',
      icon: Icons.list_alt_outlined,
      metrics: [
        SectionMetric(label: 'Sessions', value: '52'),
        SectionMetric(label: 'Filtered', value: '8'),
        SectionMetric(label: 'Strength', value: '29'),
        SectionMetric(label: 'Cardio', value: '23'),
      ],
      focusItems: ['Filter by type', 'Open recent workout', 'Compare durations'],
      initialActivities: ['Leg day selected'],
    );
  }
}
