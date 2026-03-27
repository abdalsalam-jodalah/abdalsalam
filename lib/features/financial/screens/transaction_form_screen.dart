import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/financial/category.dart';
import '../../../data/models/financial/transaction.dart';
import '../providers/financial_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/financial/transaction-form';

  const TransactionFormScreen({super.key});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.expense;
  String _category = 'Food';
  String _currency = 'USD';
  String _paymentMethod = 'Cash';

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(financialCategoriesControllerProvider);
    final categories = categoriesState.maybeWhen(data: (items) => items, orElse: () => <Category>[]);
    final filteredCategories = categories
        .where((item) => item.type == (_type == TransactionType.income ? CategoryType.income : CategoryType.expense))
        .map((item) => item.name)
        .toSet()
        .toList(growable: false)
      ..sort();

    if (filteredCategories.isEmpty) {
      _category = 'General';
    } else if (!filteredCategories.contains(_category)) {
      _category = filteredCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Financial Record'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => _showAddCategoryDialog(context),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Out')),
                  ButtonSegment(value: TransactionType.income, label: Text('In')),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() => _type = value.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g. Lunch with team',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                items: const ['USD', 'EUR', 'SAR', 'EGP', 'AED']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _currency = value ?? _currency),
                decoration: const InputDecoration(labelText: 'Currency', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: (filteredCategories.isEmpty
                        ? const ['General']
                        : filteredCategories)
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _category = value ?? _category),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                items: const ['Cash', 'Card', 'Bank Transfer', 'Wallet']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _paymentMethod = value ?? _paymentMethod),
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).dividerColor)),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Transaction Date'),
                subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'e.g. work, lunch, monthly',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  if (!(_formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  final amount = double.tryParse(_amountController.text.trim()) ?? 0;
                  final tags = _tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList(growable: false);

                  final message = await ref
                      .read(financialTransactionsControllerProvider.notifier)
                      .addTransaction(
                        amount: amount,
                        category: _category,
                        currency: _currency,
                        direction: _type,
                        date: _selectedDate,
                        description: _descriptionController.text.trim(),
                        paymentMethod: _paymentMethod,
                        tags: tags,
                      );

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message ?? 'Financial record saved')),
                  );
                  if (message == null) {
                    Navigator.of(context).maybePop();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Category'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (save != true) {
      nameController.dispose();
      return;
    }

    final message = await ref.read(financialCategoriesControllerProvider.notifier).addCategory(
          name: nameController.text.trim(),
          type: _type == TransactionType.income ? CategoryType.income : CategoryType.expense,
        );
    nameController.dispose();

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Category created')),
    );
  }
}
