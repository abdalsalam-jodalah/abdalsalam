import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../providers/sports_providers.dart';
import '../widgets/sports_activity_chart_card.dart';
import '../widgets/sports_body_weight_card.dart';
import '../widgets/sports_category_breakdown_card.dart';
import '../widgets/sports_period_selector.dart';

class SportsDashboardScreen extends ConsumerStatefulWidget {
  static const routeName = '/sports/dashboard';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SportsScreen] shell.
  final bool embedded;

  const SportsDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SportsDashboardScreen> createState() => _SportsDashboardScreenState();
}

class _SportsDashboardScreenState extends ConsumerState<SportsDashboardScreen> {
  static const String _title = 'Sport Dashboard';
  static const String _embeddedTitle = 'Dashboard';

  SportsTimePeriod _period = SportsTimePeriod.week;

  DateRangeQuery _dateRange() {
    final now = dateOnly(DateTime.now());
    switch (_period) {
      case SportsTimePeriod.day:
        return (start: now, end: now);
      case SportsTimePeriod.week:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return (start: start, end: now);
      case SportsTimePeriod.month:
        return (start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final range = _dateRange();
    final body = ListView(
      padding: EdgeInsets.all(tokens.spacing.lg),
      children: [
        if (widget.embedded) const AppSectionHeader(title: _embeddedTitle, padding: EdgeInsets.zero),
        SizedBox(height: tokens.spacing.md),
        SportsPeriodSelector(selected: _period, onChanged: (value) => setState(() => _period = value)),
        SizedBox(height: tokens.spacing.md),
        SportsActivityChartCard(range: range),
        SizedBox(height: tokens.spacing.md),
        SportsCategoryBreakdownCard(range: range),
        SizedBox(height: tokens.spacing.md),
        const SportsBodyWeightCard(),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text(_title)), body: body);
  }
}
