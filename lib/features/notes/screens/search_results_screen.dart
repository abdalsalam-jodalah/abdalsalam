import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/search_widgets.dart';

class SearchResultsScreen extends StatefulWidget {
  static const routeName = '/notes/search';

  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
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
    final filtered = _sample.where((item) {
      final full = '${item['title']} ${item['content']}'.toLowerCase();
      return _query.isEmpty || full.contains(_query.toLowerCase());
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
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
            onPressed: () => showModalBottomSheet<void>(
              context: context,
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
            padding: const EdgeInsets.all(16),
            child: DebouncedSearchBar(
              hint: 'Search notes by title/content',
              onQueryChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Status: $_status | Sort: $_sortBy'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'No matching notes',
                    subtitle: 'Try broader keywords or adjust filters.',
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: HighlightedText(
                            text: item['title']!,
                            query: _query,
                          ),
                          subtitle: HighlightedText(
                            text: item['content']!,
                            query: _query,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
