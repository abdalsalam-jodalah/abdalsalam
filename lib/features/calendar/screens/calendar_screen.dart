import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class CalendarScreen extends StatelessWidget {
  static const routeName = '/calendar';

  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Calendar Integration',
      description: 'Manage events, reminders, and schedule overview in one place.',
      icon: Icons.calendar_month_outlined,
      metrics: [
        SectionMetric(label: 'Events Today', value: '4'),
        SectionMetric(label: 'Reminders', value: '7'),
        SectionMetric(label: 'Next Meeting', value: '14:00'),
        SectionMetric(label: 'Busy Slots', value: '3'),
      ],
      focusItems: [
        'Add tomorrow meeting',
        'Review missed reminders',
        'Block deep-work window',
      ],
      initialActivities: [
        'Reminder fired: Buy medicine',
        'Event added: Family dinner',
      ],
      quickAddHint: 'Example: Dentist Tue 10 AM',
    );
  }
}
