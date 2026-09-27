import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/financial/account_model.dart';
import '../../../data/models/financial/financial_icon_palette.dart';
import '../../../core/theme/accent_palette.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/financial_providers.dart';
import '../widgets/account_tile.dart';
import '../widgets/financial_color_swatch_picker.dart';
import '../widgets/financial_delete_confirm_dialog.dart';
import '../widgets/financial_icon_option_picker.dart';

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
  static final _colorOptions = <Color>[
    for (final option in AccentPalette.options) option.color,
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
          PageHeader(
            title: 'Accounts',
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAccountDialog(),
              ),
            ],
          ),
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

  Widget _buildAccountsList() {
    final tokens = AppThemeTokens.of(context);
    final accountsAsync = ref.watch(activeAccountsProvider);

    return accountsAsync.when(
      loading: () => const LoadingSkeleton(),
      error: (error, stack) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(activeAccountsProvider),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyState(
            title: 'No accounts yet',
            subtitle: 'Tap + to add your first account',
            icon: Icons.account_balance_wallet_outlined,
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(tokens.spacing.lg),
          itemCount: accounts.length,
          separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.md),
          itemBuilder: (context, index) {
            final account = accounts[index];
            return AccountTile(
              account: account,
              balance: ref.watch(accountBalanceProvider(account)),
              onRetryBalance: () => ref.invalidate(accountBalanceProvider(account)),
              onEdit: () => _showAccountDialog(account: account),
              onDelete: () => _deleteAccount(account),
            );
          },
        );
      },
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
    await showFinancialDeleteConfirmDialog(
      context,
      title: _deleteAccountTitle,
      message: 'Are you sure you want to delete "${account.name}"?',
      cancelLabel: _cancelLabel,
      deleteLabel: _deleteLabel,
      onConfirm: () => ref.read(financialServiceProvider).deleteAccount(account),
      onDeleted: () {
        if (!mounted) return;
        ref.invalidate(allAccountsProvider);
        ref.invalidate(activeAccountsProvider);
        AppFeedback.showSuccess(context, _accountDeletedMessage);
      },
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
    final tokens = AppThemeTokens.of(context);
    final account = widget.account;
    return AppFormDialog(
      title: account == null ? 'Add Account' : 'Edit Account',
      submitLabel: account == null ? 'Create' : 'Save',
      onSubmit: () {
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
            ),
            SizedBox(height: tokens.spacing.md),
            DropdownButtonFormField<AccountType>(
              decoration: const InputDecoration(labelText: 'Type'),
              initialValue: selectedType,
              items: AccountType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value ?? selectedType),
            ),
            SizedBox(height: tokens.spacing.md),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Currency'),
              initialValue: selectedCurrency,
              items: widget.currencyOptions
                  .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCurrency = value ?? selectedCurrency),
            ),
            SizedBox(height: tokens.spacing.md),
            TextFormField(
              controller: initialBalanceController,
              decoration: const InputDecoration(labelText: 'Initial Balance'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => double.tryParse(value ?? '') == null ? 'Enter a valid amount' : null,
            ),
            SizedBox(height: tokens.spacing.md),
            FinancialIconOptionPicker(
              options: widget.iconOptions,
              selected: selectedIcon,
              accentColor: selectedColor,
              onSelected: (icon) => setState(() => selectedIcon = icon),
            ),
            SizedBox(height: tokens.spacing.sm),
            FinancialColorSwatchPicker(
              options: widget.colorOptions,
              selected: selectedColor,
              onSelected: (color) => setState(() => selectedColor = color),
            ),
          ],
        ),
      ),
    );
  }
}
