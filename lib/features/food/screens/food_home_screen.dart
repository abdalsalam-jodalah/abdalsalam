import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/food/food_log.dart';
import '../providers/food_providers.dart';
import 'food_log_form_screen.dart';

class FoodHomeScreen extends ConsumerStatefulWidget {
  static const routeName = '/food/home';

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
    if (saved == true) {
      ref.invalidate(foodLogsProvider);
      ref.invalidate(foodLogStatisticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(foodLogsProvider);
    final stats = ref.watch(foodLogStatisticsProvider);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(FoodLogFormScreen.routeName),
          icon: const Icon(Icons.add),
          label: const Text('Log Meal'),
        ),
        const SizedBox(height: 16),
        Text("Today's Totals", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Failed to load stats: $error'),
          data: (data) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories: ${_formatValue(data['todayCalories'])} kcal'),
                    Text('Protein: ${_formatValue(data['todayProteinGrams'])} g'),
                    Text('Fat: ${_formatValue(data['todayFatGrams'])} g'),
                    Text('Carbs: ${_formatValue(data['todayCarbGrams'])} g'),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text("Today's Meals", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        logs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Failed to load meals: $error'),
          data: (allLogs) {
            final groups = _groupTodayByCategory(allLogs);
            if (groups.isEmpty) {
              return const Text('No meals logged today.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in groups.entries) ...[
                  Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                  ...entry.value.map((log) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.restaurant_outlined),
                          title: Text(log.dishName),
                          subtitle: Text(log.quantity),
                          trailing: IconButton(
                            icon: const Icon(Icons.repeat),
                            onPressed: () => _logAgain(log),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ],
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(appBar: AppBar(title: const Text('Food Home')), body: body);
  }
}
