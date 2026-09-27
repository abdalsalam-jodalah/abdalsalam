// lib/features/financial/widgets/account_tile.dart: list row for a single financial account.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/financial/account_model.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class AccountTile extends ConsumerWidget {
  static const double _balanceProgressSize = 16;
  static const double _balanceProgressStrokeWidth = 2;

  final AccountModel account;
  final AsyncValue<double> balance;
  final VoidCallback onRetryBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AccountTile({
    super.key,
    required this.account,
    required this.balance,
    required this.onRetryBalance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return EntityTile(
      icon: account.icon,
      accentColor: account.color,
      title: account.name,
      subtitle: '${account.type.name} • ${account.currency}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          balance.when(
            data: (value) => Text(
              '${value.toStringAsFixed(2)} ${account.currency}',
              style: theme.textTheme.titleSmall,
            ),
            loading: () => const SizedBox(
              width: _balanceProgressSize,
              height: _balanceProgressSize,
              child: CircularProgressIndicator(strokeWidth: _balanceProgressStrokeWidth),
            ),
            error: (error, _) => IconButton(
              icon: Icon(Icons.error_outline, color: theme.colorScheme.error),
              tooltip: ref.watch(userErrorMessageMapperProvider).toUserMessage(error),
              onPressed: onRetryBalance,
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
          ),
        ],
      ),
    );
  }
}
