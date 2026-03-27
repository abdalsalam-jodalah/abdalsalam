import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/financial/transaction.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/financial_providers.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/transactions';

  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _selectedCategory = 'all';
  String _sortBy = 'date_desc';
  TransactionType? _direction;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final rowsState = ref.watch(financialTransactionsControllerProvider);
    final categoriesState = ref.watch(financialCategoriesControllerProvider);
    final categories = categoriesState.maybeWhen(
      data: (items) => items.map((item) => item.name).toSet().toList(growable: false)..sort(),
      orElse: () => <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Financial Records'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date_desc', child: Text('Newest first')),
              PopupMenuItem(value: 'date_asc', child: Text('Oldest first')),
              PopupMenuItem(value: 'amount_desc', child: Text('Amount high to low')),
              PopupMenuItem(value: 'amount_asc', child: Text('Amount low to high')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _range,
              );
              if (picked != null) {
                setState(() => _range = picked);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                _selectedCategory = 'all';
                _direction = null;
                _range = null;
                _sortBy = 'date_desc';
              });
            },
            tooltip: 'Clear filters',
          ),
        ],
      ),
      body: rowsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (rows) {
          final filtered = rows
              .where((item) {
                final categoryOk = _selectedCategory == 'all' || item.category == _selectedCategory;
                final directionOk = _direction == null || item.type == _direction;
                final startOk = _range == null || !item.date.isBefore(_range!.start);
                final endOk = _range == null || !item.date.isAfter(_range!.end);
                return categoryOk && directionOk && startOk && endOk;
              })
              .toList(growable: true);

          if (_sortBy == 'amount_desc') {
            filtered.sort((a, b) => b.amount.compareTo(a.amount));
          } else if (_sortBy == 'amount_asc') {
            filtered.sort((a, b) => a.amount.compareTo(b.amount));
          } else if (_sortBy == 'date_asc') {
            filtered.sort((a, b) => a.date.compareTo(b.date));
          } else {
            filtered.sort((a, b) => b.date.compareTo(a.date));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategory == 'all',
                      onSelected: (_) => setState(() => _selectedCategory = 'all'),
                    ),
                    ...categories.map(
                      (category) => ChoiceChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) => setState(() => _selectedCategory = category),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('In'),
                      selected: _direction == TransactionType.income,
                      onSelected: (_) => setState(
                        () => _direction = _direction == TransactionType.income ? null : TransactionType.income,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Out'),
                      selected: _direction == TransactionType.expense,
                      onSelected: (_) => setState(
                        () => _direction = _direction == TransactionType.expense ? null : TransactionType.expense,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'No records found',
                        subtitle: 'Add records or adjust filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final row = filtered[index];
                          final isIncome = row.type == TransactionType.income;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncome
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                              title: Text(row.description),
                              subtitle: Text(
                                '${row.category} • ${DateFormat('yyyy-MM-dd').format(row.date)} • ${row.currency}',
                              ),
                              trailing: Text(
                                '${isIncome ? '+' : '-'}${row.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isIncome
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed(TransactionFormScreen.routeName);
          if (mounted) {
            await ref.read(financialTransactionsControllerProvider.notifier).refreshData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }
}
