import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class HabitsScreen extends StatelessWidget {
  static const routeName = '/habits';

  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Habits & Daily Events',
      description: 'Track daily habits, events, mood trends, and streak progress.',
      icon: Icons.repeat_rounded,
      metrics: [
        SectionMetric(label: 'Active Habits', value: '6'),
        SectionMetric(label: 'Longest Streak', value: '14d'),
        SectionMetric(label: 'Today Completion', value: '58%'),
        SectionMetric(label: 'Mood', value: 'Focused'),
      ],
      focusItems: [
        'Complete morning routine',
        'Log evening reflection',
        'Check streak risks',
      ],
      initialActivities: [
        'Habit done: Drink water',
        'Mood logged: Calm',
      ],
      quickAddHint: 'Example: Read 10 pages',
    );
  }
}
