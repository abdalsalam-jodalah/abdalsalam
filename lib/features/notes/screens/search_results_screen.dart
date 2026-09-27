import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/search_widgets.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/show_app_bottom_sheet.dart';

class SearchResultsScreen extends StatefulWidget {
  static const routeName = '/notes/search';

  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  static const String _title = 'Search Results';
  static const String _searchHint = 'Search notes by title/content';
  static const String _emptyTitle = 'No matching notes';
  static const String _emptySubtitle = 'Try broader keywords or adjust filters.';

  String _query = '';
  String _sortBy = 'relevance';
  String _status = 'all';

  final List<Map<String, String>> _sample = const [
    {'title': 'Weekly plan', 'content': 'Focus on Quran reading and workout consistency'},
    {'title': 'Budget note', 'content': 'Reduce transport spending this month'},
    {'title': 'Health checklist', 'content': 'Blood test due next Tuesday'},
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final filtered = _sample.where((item) {
      final full = '${item['title']} ${item['content']}'.toLowerCase();
      return _query.isEmpty || full.contains(_query.toLowerCase());
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(_title),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'relevance', child: Text('Sort by relevance')),
              PopupMenuItem(value: 'date', child: Text('Sort by date')),
              PopupMenuItem(value: 'name', child: Text('Sort by name')),
            ],
          ),
          IconButton(
            onPressed: () => showAppBottomSheet<void>(
              context,
              builder: (context) => FilterSheet(
                statuses: const ['all', 'active', 'archived'],
                onStatusSelected: (status) => setState(() => _status = status),
              ),
            ),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(tokens.spacing.lg),
            child: DebouncedSearchBar(
              hint: _searchHint,
              onQueryChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Status: $_status | Sort: $_sortBy'),
            ),
          ),
          SizedBox(height: tokens.spacing.sm),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(title: _emptyTitle, subtitle: _emptySubtitle)
                : ListView(
                    padding: EdgeInsets.all(tokens.spacing.lg),
                    children: [
                      for (final item in filtered)
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spacing.md),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DefaultTextStyle.merge(
                                  style: theme.textTheme.titleSmall!,
                                  child: HighlightedText(text: item['title']!, query: _query),
                                ),
                                SizedBox(height: tokens.spacing.xs),
                                DefaultTextStyle.merge(
                                  style: theme.textTheme.bodySmall!
                                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  child: HighlightedText(text: item['content']!, query: _query),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
