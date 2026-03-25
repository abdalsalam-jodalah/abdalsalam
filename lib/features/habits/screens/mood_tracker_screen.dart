import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class MoodTrackerScreen extends StatelessWidget {
  static const routeName = '/habits/mood';

  const MoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Mood Tracker',
      description: 'Track mood with trends over time and correlations.',
      icon: Icons.mood_outlined,
      metrics: [
        SectionMetric(label: 'Today Mood', value: 'Calm'),
        SectionMetric(label: 'Weekly Avg', value: '7.2'),
        SectionMetric(label: 'Best Day', value: 'Friday'),
        SectionMetric(label: 'Trend', value: 'Upward'),
      ],
      focusItems: ['Log mood now', 'Review weekly trend', 'Add mood notes'],
      initialActivities: ['Mood logged at 10:20'],
    );
  }
}
