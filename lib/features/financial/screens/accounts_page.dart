import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/financial_icon_palette.dart';
import '../providers/financial_providers.dart';

class AccountsPage extends ConsumerStatefulWidget {
  static const routeName = '/financial/accounts';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FinancialScreen] shell.
  final bool embedded;

  const AccountsPage({super.key, this.embedded = false});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  static const _defaultUserId = 'user1';
  static const _iconOptions = <IconData>[
    Icons.account_balance_wallet,
    Icons.account_balance,
    Icons.credit_card,
    Icons.savings,
    Icons.payments,
  ];
  static const _colorOptions = <Color>[
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];
  static const _currencyOptions = ['ILS', 'USD', 'JOD'];

  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          _buildEmbeddedHeader(),
          Expanded(child: _buildAccountsList()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAccountDialog(),
          ),
        ],
      ),
      body: _buildAccountsList(),
    );
  }

  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Text(
            'Accounts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAccountDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    final accountsAsync = ref.watch(activeAccountsProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const Center(child: Text('Failed to load accounts')),
      data: (accounts) {
        if (accounts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No accounts yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                const Text('Tap + to add your first account'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: accounts.length,
          itemBuilder: (context, index) => _buildAccountCard(accounts[index]),
        );
      },
    );
  }

  Widget _buildAccountCard(AccountModel account) {
    final balanceAsync = ref.watch(accountBalanceProvider(account));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: account.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(account.icon, color: account.color),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${account.type.name} • ${account.currency}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            balanceAsync.when(
              data: (balance) => Text(
                '${balance.toStringAsFixed(2)} ${account.currency}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const Text('—'),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAccountDialog(account: account);
                } else if (value == 'delete') {
                  _deleteAccount(account);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccountDialog({AccountModel? account}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: account?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: account?.initialBalance.toStringAsFixed(2) ?? '0.00',
    );
    AccountType selectedType = account?.type ?? AccountType.cash;
    String selectedCurrency = account?.currency ?? _currencyOptions.first;
    IconData selectedIcon = account != null ? account.icon : _iconOptions.first;
    Color selectedColor = account != null ? Color(account.colorValue) : _colorOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(account == null ? 'Add Account' : 'Edit Account'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AccountType>(
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedType,
                    items: AccountType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedType = value ?? selectedType),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedCurrency,
                    items: _currencyOptions
                        .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedCurrency = value ?? selectedCurrency),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: initialBalanceController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Balance',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        double.tryParse(value ?? '') == null ? 'Enter a valid amount' : null,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _iconOptions
                        .map((icon) => InkWell(
                              onTap: () => setDialogState(() => selectedIcon = icon),
                              child: CircleAvatar(
                                backgroundColor: icon == selectedIcon
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey.withValues(alpha: 0.1),
                                child: Icon(icon),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _colorOptions
                        .map((color) => InkWell(
                              onTap: () => setDialogState(() => selectedColor = color),
                              child: CircleAvatar(
                                backgroundColor: color,
                                child: color == selectedColor
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(account == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      nameController.dispose();
      initialBalanceController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final initialBalance = double.parse(initialBalanceController.text);
    nameController.dispose();
    initialBalanceController.dispose();
    final service = ref.read(financialServiceProvider);
    final now = DateTime.now();

    if (account == null) {
      final result = await service.createAccount(
        AccountModel(
          id: _uuid.v4(),
          userId: _defaultUserId,
          name: name,
          type: selectedType,
          currency: selectedCurrency,
          initialBalance: initialBalance,
          iconKey: financialIconKeyFor(selectedIcon),
          colorValue: selectedColor.toARGB32(),
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _showResultSnackBar(result.isSuccess, 'Account created successfully');
    } else {
      final result = await service.updateAccount(
        account.copyWith(
          name: name,
          type: selectedType,
          currency: selectedCurrency,
          initialBalance: initialBalance,
          iconKey: financialIconKeyFor(selectedIcon),
          colorValue: selectedColor.toARGB32(),
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _showResultSnackBar(result.isSuccess, 'Account updated');
    }

    ref.invalidate(allAccountsProvider);
    ref.invalidate(activeAccountsProvider);
  }

  void _deleteAccount(AccountModel account) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await ref.read(financialServiceProvider).deleteAccount(account);
              if (!mounted) return;
              _showResultSnackBar(result.isSuccess, 'Account deleted');
              ref.invalidate(allAccountsProvider);
              ref.invalidate(activeAccountsProvider);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResultSnackBar(bool isSuccess, String successMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSuccess ? successMessage : 'Something went wrong'),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}
