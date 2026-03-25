import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class NoteCategoriesScreen extends StatelessWidget {
  static const routeName = '/notes/categories';

  const NoteCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Categories',
      description: 'Organize notes and todos with custom categories.',
      icon: Icons.folder_outlined,
      metrics: [
        SectionMetric(label: 'Categories', value: '8'),
        SectionMetric(label: 'Note Type', value: '5'),
        SectionMetric(label: 'Todo Type', value: '3'),
        SectionMetric(label: 'Subcategories', value: '4'),
      ],
      focusItems: ['Create category', 'Assign icon', 'Set color coding'],
      initialActivities: ['Category added: Learning'],
    );
  }
}
