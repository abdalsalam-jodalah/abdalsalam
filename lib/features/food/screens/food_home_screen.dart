import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/food/food_log.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/async_section.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/food_providers.dart';
import 'food_log_form_screen.dart';

class FoodHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/food/home';
  static const String _pageTitle = 'Food Home';
  static const String _dashboardTitle = 'Dashboard';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FoodScreen] shell.
  final bool embedded;

  const FoodHomeScreen({super.key, this.embedded = false});

  @override
  ConsumerState<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends ConsumerState<FoodHomeScreen> {
  String _formatValue(dynamic value) {
    final number = (value as num?)?.toDouble() ?? 0;
    return number.toStringAsFixed(0);
  }

  Map<String, List<FoodLog>> _groupTodayByCategory(List<FoodLog> logs) {
    final now = DateTime.now();
    final groups = <String, List<FoodLog>>{};
    for (final log in logs) {
      final loggedAt = log.loggedAt;
      final isToday = loggedAt.year == now.year && loggedAt.month == now.month && loggedAt.day == now.day;
      if (!isToday) continue;
      groups.putIfAbsent(log.category, () => []).add(log);
    }
    return groups;
  }

  Future<void> _logAgain(FoodLog log) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FoodLogFormScreen(template: log)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(foodLogsProvider);
      ref.invalidate(foodLogStatisticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('food');
    final logs = ref.watch(foodLogsProvider);
    final stats = ref.watch(foodLogStatisticsProvider);

    final sections = [
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(FoodLogFormScreen.routeName),
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
      AsyncSection(
        title: "Today's Totals",
        value: stats,
        onRetry: () => ref.invalidate(foodLogStatisticsProvider),
        builder: (data) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories: ${_formatValue(data['todayCalories'])} kcal'),
                Text('Protein: ${_formatValue(data['todayProteinGrams'])} g'),
                Text('Fat: ${_formatValue(data['todayFatGrams'])} g'),
                Text('Carbs: ${_formatValue(data['todayCarbGrams'])} g'),
              ],
            ),
          );
        },
      ),
      AsyncSection(
        title: "Today's Meals",
        value: logs,
        onRetry: () => ref.invalidate(foodLogsProvider),
        builder: (allLogs) {
          final groups = _groupTodayByCategory(allLogs);
          if (groups.isEmpty) {
            return const Text('No meals logged today.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in groups.entries) ...[
                AppSectionHeader(title: entry.key),
                for (final log in entry.value) ...[
                  EntityTile(
                    icon: Icons.restaurant_outlined,
                    accentColor: accent,
                    title: log.dishName,
                    subtitle: log.quantity,
                    trailing: IconButton(
                      icon: const Icon(Icons.repeat),
                      onPressed: () => _logAgain(log),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                ],
              ],
            ],
          );
        },
      ),
    ];

    if (widget.embedded) {
      return ListView(
        children: [
          const PageHeader(title: FoodHomeScreen._dashboardTitle),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final section in sections) ...[section, SizedBox(height: tokens.spacing.lg)]],
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text(FoodHomeScreen._pageTitle)),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: [for (final section in sections) ...[section, SizedBox(height: tokens.spacing.lg)]],
      ),
    );
  }
}
