import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class TodoListScreen extends StatelessWidget {
  static const routeName = '/notes/todos';

  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Todo List',
      description: 'Filter tasks by status, priority, and due date.',
      icon: Icons.checklist_outlined,
      metrics: [
        SectionMetric(label: 'Pending', value: '11'),
        SectionMetric(label: 'Done', value: '42'),
        SectionMetric(label: 'High Priority', value: '3'),
        SectionMetric(label: 'Due Today', value: '2'),
      ],
      focusItems: ['Close high priority todo', 'Sort by due date', 'Create subtask'],
      initialActivities: ['Todo done: Call lab'],
    );
  }
}
