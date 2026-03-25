import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  static const routeName = '/sports/exercise-library';

  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Exercise Library',
      description: 'Browse predefined exercises and add custom ones.',
      icon: Icons.menu_book_outlined,
      metrics: [
        SectionMetric(label: 'Predefined', value: '40'),
        SectionMetric(label: 'Custom', value: '6'),
        SectionMetric(label: 'Muscle Groups', value: '9'),
        SectionMetric(label: 'Favorites', value: '4'),
      ],
      focusItems: ['Find chest exercises', 'Add custom movement', 'Review instructions'],
      initialActivities: ['Exercise added: Bulgarian split squat'],
    );
  }
}
