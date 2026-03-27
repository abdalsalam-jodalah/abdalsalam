import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/financial/category.dart';
import '../providers/financial_providers.dart';

class FinancialCategoriesScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/categories';

  const FinancialCategoriesScreen({super.key});

  @override
  ConsumerState<FinancialCategoriesScreen> createState() => _FinancialCategoriesScreenState();
}

class _FinancialCategoriesScreenState extends ConsumerState<FinancialCategoriesScreen> {
  CategoryType _type = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financialCategoriesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<CategoryType>(
              segments: const [
                ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                ButtonSegment(value: CategoryType.income, label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
          ),
          Expanded(
            child: state.when(
              data: (categories) {
                final filtered = categories.where((item) => item.type == _type).toList(growable: false)
                  ..sort((a, b) => a.name.compareTo(b.name));
                if (filtered.isEmpty) {
                  return const Center(child: Text('No categories yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _type == CategoryType.income ? Icons.south : Icons.north,
                          color: _type == CategoryType.income
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: Text(item.name),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (save != true) {
      controller.dispose();
      return;
    }

    final message = await ref.read(financialCategoriesControllerProvider.notifier).addCategory(
          name: controller.text.trim(),
          type: _type,
        );
    controller.dispose();

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Category created')),
    );
  }
}
