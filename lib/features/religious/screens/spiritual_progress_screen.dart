import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class SpiritualProgressScreen extends StatelessWidget {
  static const routeName = '/religious/spiritual';

  const SpiritualProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Spiritual Progress',
      description: 'Journal good deeds, challenges, and daily reflections.',
      icon: Icons.auto_stories_outlined,
      metrics: [
        SectionMetric(label: 'Entries This Week', value: '5'),
        SectionMetric(label: 'Mood Trend', value: 'Stable'),
        SectionMetric(label: 'Good Deeds', value: '18'),
        SectionMetric(label: 'Average Rating', value: '4.2'),
      ],
      focusItems: [
        'Write evening reflection',
        'List one gratitude',
        'Track today mood',
      ],
      initialActivities: [
        'Reflection added for Tuesday',
        'Mood set to grateful',
      ],
      quickAddHint: 'Example: Helped family and read Quran',
    );
  }
}
