import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/food/food_log.dart';
import '../providers/food_providers.dart';
import 'food_log_form_screen.dart';

class FoodLogsScreen extends ConsumerStatefulWidget {
  static const routeName = '/food/logs';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [FoodScreen] shell.
  final bool embedded;

  const FoodLogsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<FoodLogsScreen> createState() => _FoodLogsScreenState();
}

class _FoodLogsScreenState extends ConsumerState<FoodLogsScreen> {
  Future<void> _delete(FoodLog log) async {
    final service = ref.read(foodLogServiceProvider);
    await service.softDelete(log.id);
    ref.invalidate(foodLogsProvider);
    ref.invalidate(foodLogStatisticsProvider);
  }

  Future<void> _openForm({FoodLog? log}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FoodLogFormScreen(log: log)),
    );
    if (saved == true) {
      ref.invalidate(foodLogsProvider);
      ref.invalidate(foodLogStatisticsProvider);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, List<FoodLog>> _groupByDay(List<FoodLog> logs) {
    final groups = <String, List<FoodLog>>{};
    for (final log in logs) {
      final key = _formatDate(log.loggedAt);
      groups.putIfAbsent(key, () => []).add(log);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(foodLogsProvider);

    final content = logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load food logs: $error')),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No food logs yet. Tap + to add one.'));
        }

        final groups = _groupByDay(logs);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Food Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            for (final entry in groups.entries) ...[
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...entry.value.map((log) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant_outlined),
                      title: Text('${log.category}: ${log.dishName}'),
                      subtitle: Text(
                        '${log.quantity}'
                        '${log.calories != null ? ' • ${log.calories!.toStringAsFixed(0)} kcal' : ''}',
                      ),
                      onTap: () => _openForm(log: log),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(log),
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
    final fab = FloatingActionButton(
      onPressed: () => _openForm(),
      child: const Icon(Icons.add),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          content,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Food Logs')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
