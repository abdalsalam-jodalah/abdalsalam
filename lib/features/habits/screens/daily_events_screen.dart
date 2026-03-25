import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class DailyEventsScreen extends StatelessWidget {
  static const routeName = '/habits/daily-events';

  const DailyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Daily Events',
      description: 'Journal meaningful events and related habit impact.',
      icon: Icons.event_note_outlined,
      metrics: [
        SectionMetric(label: 'Today Events', value: '3'),
        SectionMetric(label: 'Weekly Logs', value: '17'),
        SectionMetric(label: 'Tagged', value: '9'),
        SectionMetric(label: 'Mood Entries', value: '12'),
      ],
      focusItems: ['Log event', 'Tag event', 'Relate event to habit'],
      initialActivities: ['Event logged: Team meeting'],
    );
  }
}
