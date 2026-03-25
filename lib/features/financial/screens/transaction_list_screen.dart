import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/search_widgets.dart';

class TransactionListScreen extends StatefulWidget {
  static const routeName = '/financial/transactions';

  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  bool _loading = false;
  String _query = '';
  String _status = 'all';
  String _sortBy = 'date';

  final List<Map<String, dynamic>> _rows = [
    {'title': 'Salary', 'amount': 1200.0, 'type': 'income', 'date': DateTime.now()},
    {'title': 'Food', 'amount': 45.0, 'type': 'expense', 'date': DateTime.now().subtract(const Duration(days: 1))},
    {'title': 'Transport', 'amount': 20.0, 'type': 'expense', 'date': DateTime.now().subtract(const Duration(days: 2))},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _rows.where((row) {
      final matchQuery = _query.isEmpty || row['title'].toString().toLowerCase().contains(_query.toLowerCase());
      final matchStatus = _status == 'all' || row['type'] == _status;
      return matchQuery && matchStatus;
    }).toList(growable: true);

    if (_sortBy == 'amount') {
      filtered.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a['title'].toString().compareTo(b['title'].toString()));
    } else {
      filtered.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date', child: Text('Sort by date')),
              PopupMenuItem(value: 'name', child: Text('Sort by name')),
              PopupMenuItem(value: 'amount', child: Text('Sort by amount')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => FilterSheet(
                statuses: const ['all', 'income', 'expense'],
                onStatusSelected: (value) => setState(() => _status = value),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          setState(() => _loading = false);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DebouncedSearchBar(
                hint: 'Search by description/category/tags',
                onQueryChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: _loading
                  ? const LoadingSkeleton(lines: 6)
                  : filtered.isEmpty
                      ? const EmptyState(
                          title: 'No transactions found',
                          subtitle: 'Adjust filters or add a new transaction.',
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final row = filtered[index];
                            return Dismissible(
                              key: ValueKey('${row['title']}_$index'),
                              background: Container(
                                color: Colors.green,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async => false,
                              child: ListTile(
                                title: HighlightedText(text: row['title'].toString(), query: _query),
                                subtitle: Text(row['type'].toString()),
                                trailing: Text('\$${row['amount']}'),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
