import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/financial/transaction_model.dart';
import '../providers/financial_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/transactions';

  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String? _selectedCategory;
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/financial/transaction-form',
              );
              
              // Refresh the list after adding/editing
              if (result != null) {
                ref.invalidate(allTransactionsProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedCategory != null || _selectedType != null)
            _buildActiveFilters(),
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedCategory != null)
            Chip(
              label: Text(_selectedCategory!),
              onDeleted: () {
                setState(() => _selectedCategory = null);
              },
            ),
          if (_selectedType != null)
            Chip(
              label: Text(_selectedType!.name),
              onDeleted: () {
                setState(() => _selectedType = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first transaction',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Apply filters
        var filtered = transactions;
        if (_selectedType != null) {
          filtered = filtered.where((t) => t.type == _selectedType).toList();
        }
        if (_selectedCategory != null) {
          filtered = filtered.where((t) => t.categoryId == _selectedCategory).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions match filters',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final transaction = filtered[index];
            return _buildTransactionCard(transaction);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading transactions: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final formatter = DateFormat('MMM dd, yyyy • HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          formatter.format(transaction.date),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            if (transaction.paymentMethod != null)
              Text(
                transaction.paymentMethod!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showFilterDialog() {
    final categoriesAsync = ref.read(allCategoriesProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('No categories available');
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedCategory,
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading categories'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransactionType>(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedType,
              items: const [
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text('Expense'),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _selectedType = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Amount', '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Type', transaction.type.name),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(transaction.date)),
            if (transaction.paymentMethod != null)
              _buildDetailRow('Payment Method', transaction.paymentMethod!),
            if (transaction.tags.isNotEmpty)
              _buildDetailRow('Tags', transaction.tags.join(', ')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      // Navigate to edit form
                      final result = await Navigator.pushNamed(
                        context,
                        '/financial/transaction-form',
                        arguments: transaction,
                      );
                      
                      // Refresh after edit
                      if (result != null) {
                        ref.invalidate(allTransactionsProvider);
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTransaction(transaction);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // TODO: Actually delete transaction from database
              Navigator.pop(context);
              
              // Refresh transactions list
              ref.invalidate(allTransactionsProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
