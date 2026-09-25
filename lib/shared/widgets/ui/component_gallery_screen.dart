import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../charts/app_bar_chart.dart';
import '../charts/app_line_chart.dart';
import '../charts/app_pie_chart.dart';
import '../empty_state.dart';
import 'app_card.dart';
import 'app_section_header.dart';
import 'async_section.dart';
import 'date_time_field.dart';
import 'entity_tile.dart';
import 'filter_bar.dart';
import 'filter_option.dart';
import 'month_heatmap.dart';
import 'page_header.dart';
import 'progress_bar.dart';
import 'progress_ring.dart';
import 'show_confirm_dialog.dart';
import 'stat_grid.dart';
import 'stat_tile.dart';

class ComponentGalleryScreen extends StatefulWidget {
  static const routeName = '/dev/gallery';

  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  static const List<double> _sampleTrend = <double>[3, 4, 3.5, 5, 4.6, 6, 5.4];
  static const List<double> _sampleBars = <double>[42, 50, 46, 58, 62];
  static const Map<String, double> _sampleShare = <String, double>{'Needs': 50, 'Wants': 30, 'Savings': 20};
  static const double _goalProgress = 0.72;
  static const int _heatmapCycle = 4;

  String _filter = 'week';
  DateTime? _date = DateTime(2026, 9, 24);

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final spacing = tokens.spacing;
    return Scaffold(
      appBar: AppBar(title: const Text('Component gallery')),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          const PageHeader(title: 'Good morning', subtitle: 'Here is your day at a glance'),
          StatGrid(
            children: [
              StatTile(
                icon: Icons.mosque_rounded,
                label: 'Prayers today',
                value: '4 / 5',
                accentColor: AppModuleAccents.forModule('religious'),
              ),
              StatTile(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Spent this month',
                value: '₪ 1,240',
                caption: '12% under budget',
                accentColor: tokens.colors.income,
              ),
              StatTile(
                icon: Icons.bedtime_rounded,
                label: 'Sleep last night',
                value: '7h 20m',
                accentColor: AppModuleAccents.forModule('sleep'),
              ),
            ],
          ),
          const AppSectionHeader(title: 'Filters', subtitle: 'Chips scroll horizontally'),
          FilterBar<String>(
            options: const [
              FilterOption('day', 'Day'),
              FilterOption('week', 'Week'),
              FilterOption('month', 'Month'),
              FilterOption('year', 'Year'),
            ],
            selected: _filter,
            onSelected: (value) => setState(() => _filter = value),
          ),
          const AppSectionHeader(title: 'List items'),
          EntityTile(
            icon: Icons.restaurant_rounded,
            accentColor: tokens.colors.expense,
            title: 'Groceries',
            subtitle: 'Today · Card',
            trailing: Text('-₪ 86.00', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: tokens.colors.expense)),
            onTap: () {},
          ),
          SizedBox(height: spacing.sm),
          EntityTile(
            icon: Icons.work_rounded,
            accentColor: tokens.colors.income,
            title: 'Salary',
            subtitle: 'Sep 1 · Bank transfer',
            trailing: Text('+₪ 9,500', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: tokens.colors.income)),
          ),
          const AppSectionHeader(title: 'Progress'),
          AppCard(
            child: Row(
              children: [
                ProgressRing(
                  value: _goalProgress,
                  center: Text('72%', style: Theme.of(context).textTheme.labelLarge),
                ),
                SizedBox(width: spacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Read 20 pages', style: Theme.of(context).textTheme.titleSmall),
                      SizedBox(height: spacing.sm),
                      const ProgressBar(value: _goalProgress),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AsyncSection<List<double>>(
            title: 'Weekly trend',
            value: const AsyncValue.data(_sampleTrend),
            builder: (points) => AppCard(child: AppLineChart(points: points)),
          ),
          AsyncSection<void>(
            title: 'A section that failed',
            value: AsyncValue.error(DatabaseError('raw storage text'), StackTrace.empty),
            onRetry: () {},
            builder: (_) => const SizedBox.shrink(),
          ),
          const AppSectionHeader(title: 'Charts'),
          const AppCard(child: AppBarChart(values: _sampleBars)),
          SizedBox(height: spacing.sm),
          const AppCard(child: AppPieChart(values: _sampleShare)),
          const AppSectionHeader(title: 'Month heatmap'),
          AppCard(
            child: MonthHeatmap(
              month: DateTime(2026, 9),
              intensityForDay: (day) => (day.day % _heatmapCycle) / (_heatmapCycle - 1),
            ),
          ),
          const AppSectionHeader(title: 'Inputs'),
          DateTimeField(
            label: 'Due date',
            value: _date,
            isClearable: true,
            onChanged: (value) => setState(() => _date = value),
          ),
          SizedBox(height: spacing.md),
          const TextField(decoration: InputDecoration(labelText: 'Title', hintText: 'What do you want to track?')),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Save')),
              OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
              TextButton(
                onPressed: () => showConfirmDialog(
                  context,
                  title: 'Delete habit?',
                  message: 'This removes the habit and its history.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                  icon: Icons.delete_outline_rounded,
                ),
                child: const Text('Delete…'),
              ),
            ],
          ),
          const AppSectionHeader(title: 'Empty state'),
          const AppCard(
            child: EmptyState(
              title: 'No notes yet',
              subtitle: 'Capture your first idea',
              icon: Icons.sticky_note_2_rounded,
              isCompact: true,
            ),
          ),
          SizedBox(height: spacing.xxl),
        ],
      ),
    );
  }
}
