import 'package:flutter/material.dart';

class TransactionFormScreen extends StatefulWidget {
  static const routeName = '/financial/transaction-form';

  const TransactionFormScreen({super.key});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense';
  String _category = 'Food';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Form')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
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
                  prefixText: '\$',
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
                initialValue: _category,
                items: const ['Food', 'Transport', 'Health', 'Entertainment', 'Bills', 'Salary', 'Investment']
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
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction saved')),
                    );
                    Navigator.of(context).maybePop();
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
