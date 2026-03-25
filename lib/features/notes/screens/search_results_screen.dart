import 'package:flutter/material.dart';

import '../../../shared/widgets/section_placeholder_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  static const routeName = '/notes/search';

  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionPlaceholderScreen(
      title: 'Search Results',
      description: 'Find notes by title/content with highlighted matches.',
      icon: Icons.search,
      metrics: [
        SectionMetric(label: 'Matches', value: '14'),
        SectionMetric(label: 'Title Hits', value: '6'),
        SectionMetric(label: 'Content Hits', value: '8'),
        SectionMetric(label: 'Tags', value: '4'),
      ],
      focusItems: ['Refine search', 'Filter by category', 'Open best match'],
      initialActivities: ['Search: weekly plan'],
    );
  }
}
