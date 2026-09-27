import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/food/food_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
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
    final result = await service.softDelete(log.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(foodLogsProvider);
    ref.invalidate(foodLogStatisticsProvider);
  }

  Future<void> _openForm({FoodLog? log}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => FoodLogFormScreen(log: log)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(foodLogsProvider);
      ref.invalidate(foodLogStatisticsProvider);
    }
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

  Map<String, List<FoodLog>> _groupByDay(List<FoodLog> logs) {
    final groups = <String, List<FoodLog>>{};
    for (final log in logs) {
      final key = AppDateFormatter.date(log.loggedAt);
      groups.putIfAbsent(key, () => []).add(log);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('food');
    final logsAsync = ref.watch(foodLogsProvider);

    final content = logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(foodLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No food logs yet. Tap + to add one.'));
        }

        final groups = _groupByDay(logs);
        return ListView(
          children: [
            if (widget.embedded) const PageHeader(title: 'Food Logs'),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spacing.lg,
                widget.embedded ? 0 : tokens.spacing.lg,
                tokens.spacing.lg,
                tokens.spacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final entry in groups.entries) ...[
                    AppSectionHeader(title: entry.key, padding: EdgeInsets.zero),
                    SizedBox(height: tokens.spacing.sm),
                    for (final log in entry.value) ...[
                      EntityTile(
                        icon: Icons.restaurant_outlined,
                        accentColor: accent,
                        title: '${log.category}: ${log.dishName}',
                        subtitle: '${log.quantity}'
                            '${log.calories != null ? ' • ${log.calories!.toStringAsFixed(0)} kcal' : ''}',
                        onTap: () => _openForm(log: log),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.repeat),
                              onPressed: () => _logAgain(log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(log),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: tokens.spacing.sm),
                    ],
                    SizedBox(height: tokens.spacing.sm),
                  ],
                ],
              ),
            ),
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
          Positioned(right: tokens.spacing.lg, bottom: tokens.spacing.lg, child: fab),
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
