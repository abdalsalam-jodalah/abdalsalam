import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import 'money_text.dart';

class FinancialTransactionTile extends StatelessWidget {
  final String title;
  final String categoryName;
  final double signedAmount;
  final DateTime date;
  final IconData icon;
  final Color accentColor;

  const FinancialTransactionTile({
    super.key,
    required this.title,
    required this.categoryName,
    required this.signedAmount,
    required this.date,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return EntityTile(
      icon: icon,
      accentColor: accentColor,
      title: title,
      subtitle: '$categoryName • ${AppDateFormatter.shortDate(date)}',
      trailing: MoneyText(
        signedAmount,
        showPlusSign: true,
        colorByAmount: true,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
