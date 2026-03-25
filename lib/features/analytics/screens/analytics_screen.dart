import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/chart_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementServiceProvider).milestones();
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
          Text('Trend Charts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: TrendLineChart(points: [62, 64, 68, 66, 72, 74, 75]),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: DistributionPieChart(values: {
                'Needs': 58,
                'Learning': 19,
                'Leisure': 13,
                'Other': 10,
              }),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: ComparisonBarChart(values: [42, 50, 46, 58, 62]),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chart detail: tap interactions enabled in next iteration.')),
                );
              },
              icon: const Icon(Icons.touch_app_outlined),
              label: const Text('View chart details'),
            ),
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
          ...achievements.map(
            (entry) => ListTile(
              dense: true,
              title: Text(entry['title'] as String),
              subtitle: LinearProgressIndicator(
                value: ((entry['current'] as int) / (entry['target'] as int)).clamp(0.0, 1.0),
              ),
              trailing: Text('${entry['current']}/${entry['target']}'),
            ),
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
