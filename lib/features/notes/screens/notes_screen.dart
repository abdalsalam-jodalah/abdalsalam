import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class NotesScreen extends StatelessWidget {
  static const routeName = '/notes';

  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Notes & Tasks',
      description: 'Capture notes, todos, and categorized personal knowledge.',
      icon: Icons.sticky_note_2_outlined,
      metrics: [
        SectionMetric(label: 'Open Todos', value: '9'),
        SectionMetric(label: 'Notes This Week', value: '12'),
        SectionMetric(label: 'Pinned Notes', value: '3'),
        SectionMetric(label: 'Completion Rate', value: '71%'),
      ],
      focusItems: [
        'Close high-priority todo',
        'Write daily journal note',
        'Tag uncategorized notes',
      ],
      initialActivities: [
        'Todo done: Send monthly report',
        'Note created: Sprint ideas',
      ],
      quickAddHint: 'Example: Call lab at 5 PM',
    );
  }
}
