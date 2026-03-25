import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class SportsScreen extends StatelessWidget {
  static const routeName = '/sports';

  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Sports & Fitness',
      description: 'Track workouts, sets, durations, and weekly fitness volume.',
      icon: Icons.fitness_center,
      metrics: [
        SectionMetric(label: 'Workouts This Week', value: '3'),
        SectionMetric(label: 'Minutes Trained', value: '145'),
        SectionMetric(label: 'Next Session', value: 'Tomorrow'),
        SectionMetric(label: 'Best Streak', value: '5d'),
      ],
      focusItems: [
        'Plan next workout',
        'Log today training',
        'Review progress chart',
      ],
      initialActivities: [
        'Push day completed - 45 min',
        'Walking session added - 6,200 steps',
      ],
      quickAddHint: 'Example: Leg day 40 min',
    );
  }
}
