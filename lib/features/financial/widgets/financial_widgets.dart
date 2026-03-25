import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: const Text('Current Balance'),
        subtitle: Text(balance.toStringAsFixed(2)),
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> values;

  const CategoryPieChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Category distribution: ${values.length} categories'),
      ),
    );
  }
}

class MonthlySpendingChart extends StatelessWidget {
  final List<double> monthlyValues;

  const MonthlySpendingChart({super.key, required this.monthlyValues});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Monthly points: ${monthlyValues.length}'),
      ),
    );
  }
}

class BudgetProgressBar extends StatelessWidget {
  final double progress;

  const BudgetProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Budget usage'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress.clamp(0, 1)),
      ],
    );
  }
}
