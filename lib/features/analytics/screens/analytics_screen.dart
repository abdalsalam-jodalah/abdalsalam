import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/charts/app_bar_chart.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/charts/app_pie_chart.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/progress_bar.dart';
import '../../../shared/widgets/ui/stat_grid.dart';
import '../../../shared/widgets/ui/stat_tile.dart';

class AnalyticsScreen extends ConsumerWidget {
  static const routeName = '/analytics';

  static const List<double> _weeklyTrendPoints = [62, 64, 68, 66, 72, 74, 75];
  static const Map<String, double> _spendingShare = {
    'Needs': 58,
    'Learning': 19,
    'Leisure': 13,
    'Other': 10,
  };
  static const List<double> _monthlyBars = [42, 50, 46, 58, 62];
  static const List<String> _crossModuleInsights = [
    'Workout days align with better mood scores.',
    'Prayer completion consistency improved focus streak.',
    'Higher spending appears on missed habit days.',
  ];

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final achievements = ref.watch(achievementServiceProvider).milestones();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard & Analytics')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [
          StatGrid(
            children: [
              StatTile(
                icon: Icons.trending_up,
                label: 'Weekly Consistency',
                value: '74%',
                caption: 'Up 6% from last week',
                accentColor: tokens.colors.success,
              ),
              StatTile(
                icon: Icons.monitor_heart_outlined,
                label: 'Mood vs Workout Correlation',
                value: '0.61',
                caption: 'Positive relationship detected',
                accentColor: tokens.colors.info,
              ),
              StatTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Spending vs Income',
                value: '81%',
                caption: 'Current monthly expense ratio',
                accentColor: tokens.colors.expense,
              ),
            ],
          ),
          AppSectionHeader(title: 'Trend Charts', padding: EdgeInsets.only(top: tokens.spacing.lg, bottom: tokens.spacing.sm)),
          AppCard(child: AppLineChart(points: _weeklyTrendPoints)),
          SizedBox(height: tokens.spacing.sm),
          AppCard(child: AppPieChart(values: _spendingShare)),
          SizedBox(height: tokens.spacing.sm),
          AppCard(child: AppBarChart(values: _monthlyBars)),
          SizedBox(height: tokens.spacing.sm),
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
          AppSectionHeader(title: 'Cross-module Insights', padding: EdgeInsets.only(top: tokens.spacing.lg, bottom: tokens.spacing.sm)),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _crossModuleInsights.length; index++) ...[
                  if (index > 0) SizedBox(height: tokens.spacing.xs),
                  Text('• ${_crossModuleInsights[index]}', style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          AppSectionHeader(title: 'Achievements', padding: EdgeInsets.only(top: tokens.spacing.lg, bottom: tokens.spacing.sm)),
          for (final achievement in achievements) ...[
            _AchievementCard(
              title: achievement['title'] as String,
              current: achievement['current'] as int,
              target: achievement['target'] as int,
            ),
            SizedBox(height: tokens.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  final int current;
  final int target;

  const _AchievementCard({required this.title, required this.current, required this.target});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              Text('$current/$target', style: theme.textTheme.labelLarge),
            ],
          ),
          SizedBox(height: tokens.spacing.sm),
          ProgressBar(value: target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}
