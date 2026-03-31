import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/financial/budget_model.dart';
import '../providers/financial_providers.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/budgets';

  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodFilter(),
          Expanded(
            child: _buildBudgetsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<BudgetPeriod>(
        segments: const [
          ButtonSegment(
            value: BudgetPeriod.daily,
            label: Text('Day'),
          ),
          ButtonSegment(
            value: BudgetPeriod.weekly,
            label: Text('Week'),
          ),
          ButtonSegment(
            value: BudgetPeriod.monthly,
            label: Text('Month'),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (Set<BudgetPeriod> newSelection) {
          setState(() {
            _selectedPeriod = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildBudgetsList() {
    final budgets = _getSampleBudgets();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, index) {
        final budget = budgets[index];
        return _buildBudgetCard(budget);
      },
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    // Sample spent amount - replace with real data
    final spent = budget.amount * 0.65;
    final percentage = (spent / budget.amount) * 100;
    final remaining = budget.amount - spent;
    final isOverBudget = spent > budget.amount;
    final isNearLimit = percentage >= budget.alertThreshold;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(budget.categoryId).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(budget.categoryId),
                    color: _getCategoryColor(budget.categoryId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryName(budget.categoryId),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        budget.period.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget
                            ? Colors.red
                            : isNearLimit
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    if (isOverBudget)
                      const Text(
                        'Over Budget',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? Colors.red
                      : isNearLimit
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${spent.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remaining < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${budget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editBudget(budget),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBudget(budget),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
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

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cat1', child: Text('Groceries')),
                  DropdownMenuItem(value: 'cat2', child: Text('Transport')),
                  DropdownMenuItem(value: 'cat3', child: Text('Entertainment')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                decoration: const InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(),
                ),
                initialValue: BudgetPeriod.monthly,
                items: const [
                  DropdownMenuItem(
                    value: BudgetPeriod.daily,
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: BudgetPeriod.weekly,
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: BudgetPeriod.monthly,
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Actually save budget to database
              Navigator.pop(context);
              
              // Refresh budgets list
              ref.invalidate(activeBudgetsProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editBudget(BudgetModel budget) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit budget coming soon')),
    );
  }

  void _deleteBudget(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Actually delete budget from database
              Navigator.pop(context);
              
              // Refresh budgets list
              ref.invalidate(activeBudgetsProvider);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget deleted'),
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

  List<BudgetModel> _getSampleBudgets() {
    final now = DateTime.now();
    return [
      BudgetModel(
        id: '1',
        userId: 'user1',
        categoryId: 'cat1',
        amount: 500,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: '2',
        userId: 'user1',
        categoryId: 'cat2',
        amount: 200,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
        updatedAt: now,
      ),
      BudgetModel(
        id: '3',
        userId: 'user1',
        categoryId: 'cat3',
        amount: 300,
        period: BudgetPeriod.monthly,
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'cat1':
        return 'Groceries';
      case 'cat2':
        return 'Transport';
      case 'cat3':
        return 'Entertainment';
      default:
        return 'Unknown';
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'cat1':
        return Icons.shopping_cart;
      case 'cat2':
        return Icons.directions_car;
      case 'cat3':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'cat1':
        return Colors.orange;
      case 'cat2':
        return Colors.blue;
      case 'cat3':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
