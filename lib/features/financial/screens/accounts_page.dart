import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/financial_icon_palette.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/app_feedback.dart';
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
  static const String _accountCreatedMessage = 'Account created successfully';
  static const String _accountUpdatedMessage = 'Account updated';
  static const String _accountDeletedMessage = 'Account deleted';
  static const String _deleteAccountTitle = 'Delete Account';
  static const String _cancelLabel = 'Cancel';
  static const String _deleteLabel = 'Delete';

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
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeAccountsProvider),
      ),
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
              error: (error, _) => IconButton(
                icon: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                tooltip: ref.watch(userErrorMessageMapperProvider).toUserMessage(error),
                onPressed: () => ref.invalidate(accountBalanceProvider(account)),
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  await _showAccountDialog(account: account);
                } else if (value == 'delete') {
                  await _deleteAccount(account);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAccountDialog({AccountModel? account}) async {
    final result = await showDialog<_AccountDialogResult>(
      context: context,
      builder: (_) => _AccountDialogContent(
        account: account,
        iconOptions: _iconOptions,
        colorOptions: _colorOptions,
        currencyOptions: _currencyOptions,
      ),
    );

    if (result == null || !mounted) return;

    final service = ref.read(financialServiceProvider);
    final now = DateTime.now();

    if (account == null) {
      final saveResult = await service.createAccount(
        AccountModel(
          id: _uuid.v4(),
          userId: _defaultUserId,
          name: result.name,
          type: result.type,
          currency: result.currency,
          initialBalance: result.initialBalance,
          iconKey: financialIconKeyFor(result.icon),
          colorValue: result.color.toARGB32(),
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _accountCreatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    } else {
      final saveResult = await service.updateAccount(
        account.copyWith(
          name: result.name,
          type: result.type,
          currency: result.currency,
          initialBalance: result.initialBalance,
          iconKey: financialIconKeyFor(result.icon),
          colorValue: result.color.toARGB32(),
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      if (saveResult.isSuccess) {
        AppFeedback.showSuccess(context, _accountUpdatedMessage);
      } else {
        AppFeedback.showError(context, saveResult.error!);
        return;
      }
    }

    ref.invalidate(allAccountsProvider);
    ref.invalidate(activeAccountsProvider);
  }

  Future<void> _deleteAccount(AccountModel account) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(_deleteAccountTitle),
        content: Text('Are you sure you want to delete "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(_cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              final result = await ref.read(financialServiceProvider).deleteAccount(account);
              if (!dialogContext.mounted) return;

              if (result.isSuccess) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ref.invalidate(allAccountsProvider);
                  ref.invalidate(activeAccountsProvider);
                  AppFeedback.showSuccess(context, _accountDeletedMessage);
                }
              } else {
                AppFeedback.showError(dialogContext, result.error!);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(_deleteLabel),
          ),
        ],
      ),
    );
  }
}

class _AccountDialogResult {
  _AccountDialogResult({
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.icon,
    required this.color,
  });

  final String name;
  final AccountType type;
  final String currency;
  final double initialBalance;
  final IconData icon;
  final Color color;
}

class _AccountDialogContent extends StatefulWidget {
  const _AccountDialogContent({
    required this.account,
    required this.iconOptions,
    required this.colorOptions,
    required this.currencyOptions,
  });

  final AccountModel? account;
  final List<IconData> iconOptions;
  final List<Color> colorOptions;
  final List<String> currencyOptions;

  @override
  State<_AccountDialogContent> createState() => _AccountDialogContentState();
}

class _AccountDialogContentState extends State<_AccountDialogContent> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController initialBalanceController;
  late AccountType selectedType;
  late String selectedCurrency;
  late IconData selectedIcon;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    nameController = TextEditingController(text: account?.name ?? '');
    initialBalanceController = TextEditingController(
      text: account?.initialBalance.toStringAsFixed(2) ?? '0.00',
    );
    selectedType = account?.type ?? AccountType.cash;
    selectedCurrency = account?.currency ?? widget.currencyOptions.first;
    selectedIcon = account != null ? account.icon : widget.iconOptions.first;
    selectedColor = account != null ? Color(account.colorValue) : widget.colorOptions.first;
  }

  @override
  void dispose() {
    nameController.dispose();
    initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return AlertDialog(
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
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AccountType>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedType,
                items: AccountType.values
                    .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                    .toList(),
                onChanged: (value) => setState(() => selectedType = value ?? selectedType),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedCurrency,
                items: widget.currencyOptions.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                onChanged: (value) => setState(() => selectedCurrency = value ?? selectedCurrency),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: initialBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => double.tryParse(value ?? '') == null ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: widget.iconOptions
                    .map((icon) => InkWell(
                          onTap: () => setState(() => selectedIcon = icon),
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
                children: widget.colorOptions
                    .map((color) => InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          child: CircleAvatar(
                            backgroundColor: color,
                            child: color == selectedColor ? const Icon(Icons.check, color: Colors.white) : null,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(
                context,
                _AccountDialogResult(
                  name: nameController.text.trim(),
                  type: selectedType,
                  currency: selectedCurrency,
                  initialBalance: double.parse(initialBalanceController.text),
                  icon: selectedIcon,
                  color: selectedColor,
                ),
              );
            }
          },
          child: Text(account == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
