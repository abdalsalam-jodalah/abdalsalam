// lib/features/financial/widgets/activity_log_entry_tile.dart: list row for a single financial activity log entry.
import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/financial/financial_activity_log_model.dart';
import '../../../shared/widgets/ui/entity_tile.dart';

class ActivityLogEntryTile extends StatelessWidget {
  final FinancialActivityLogModel entry;

  const ActivityLogEntryTile({super.key, required this.entry});

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

  Color _colorFor(BuildContext context, FinancialActionType action) {
    final tokens = AppThemeTokens.of(context);
    switch (action) {
      case FinancialActionType.created:
        return tokens.colors.success;
      case FinancialActionType.updated:
        return tokens.colors.info;
      case FinancialActionType.deleted:
        return tokens.colors.danger;
      case FinancialActionType.recurringGenerated:
        return AppModuleAccents.forModule('financial');
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

  @override
  Widget build(BuildContext context) {
    final accentColor = _colorFor(context, entry.action);
    return EntityTile(
      icon: _iconFor(entry.entityType),
      accentColor: accentColor,
      title: entry.summary,
      subtitle: '${_actionLabel(entry.action)} • ${AppDateFormatter.dateTime(entry.createdAt)}',
    );
  }
}
