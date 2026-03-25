import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InsightCard(
            title: 'Weekly Consistency',
            value: '74%',
            detail: 'Up 6% from last week',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 10),
          const _InsightCard(
            title: 'Mood vs Workout Correlation',
            value: '0.61',
            detail: 'Positive relationship detected',
            icon: Icons.monitor_heart_outlined,
          ),
          const SizedBox(height: 10),
          const _InsightCard(
            title: 'Spending vs Income',
            value: '81%',
            detail: 'Current monthly expense ratio',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 14),
          Text('Cross-module Insights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Workout days align with better mood scores.'),
                  SizedBox(height: 6),
                  Text('• Prayer completion consistency improved focus streak.'),
                  SizedBox(height: 6),
                  Text('• Higher spending appears on missed habit days.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('30-Day Prayer Streak')),
              Chip(label: Text('100 Workouts Logged')),
              Chip(label: Text('90% Todo Completion')),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String detail;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(detail),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
