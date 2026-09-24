import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/financial_providers.dart';

class FinancialActivityLogScreen extends ConsumerWidget {
  static const routeName = '/financial/activity-log';

  const FinancialActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(recentActivityLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      body: logAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(recentActivityLogProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  const Text('No financial activity yet'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildEntryCard(context, entries[index]),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, FinancialActivityLogModel entry) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorFor(entry.action).withValues(alpha: 0.15),
          child: Icon(_iconFor(entry.entityType), color: _colorFor(entry.action)),
        ),
        title: Text(entry.summary),
        subtitle: Text(
          '${_actionLabel(entry.action)} • ${DateFormat('MMM d, yyyy HH:mm').format(entry.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  IconData _iconFor(FinancialEntityType type) {
    switch (type) {
      case FinancialEntityType.transaction:
        return Icons.receipt_long;
      case FinancialEntityType.budget:
        return Icons.savings;
      case FinancialEntityType.category:
        return Icons.category;
      case FinancialEntityType.account:
        return Icons.account_balance_wallet;
    }
  }

  Color _colorFor(FinancialActionType action) {
    switch (action) {
      case FinancialActionType.created:
        return Colors.green;
      case FinancialActionType.updated:
        return Colors.blue;
      case FinancialActionType.deleted:
        return Colors.red;
      case FinancialActionType.recurringGenerated:
        return Colors.purple;
    }
  }

  String _actionLabel(FinancialActionType action) {
    switch (action) {
      case FinancialActionType.created:
        return 'Created';
      case FinancialActionType.updated:
        return 'Updated';
      case FinancialActionType.deleted:
        return 'Deleted';
      case FinancialActionType.recurringGenerated:
        return 'Auto-generated';
    }
  }
}
