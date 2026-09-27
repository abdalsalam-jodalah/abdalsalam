import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../providers/financial_providers.dart';
import '../widgets/activity_log_entry_tile.dart';

class FinancialActivityLogScreen extends ConsumerWidget {
  static const routeName = '/financial/activity-log';

  const FinancialActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final logAsync = ref.watch(recentActivityLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      body: logAsync.when(
        loading: () => const LoadingSkeleton(),
        error: (error, stack) => AsyncErrorView(
          error: error,
          onRetry: () => ref.invalidate(recentActivityLogProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              title: 'No financial activity yet',
              subtitle: 'Actions you take across financial will show up here',
              icon: Icons.history,
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(tokens.spacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, _) => SizedBox(height: tokens.spacing.sm),
            itemBuilder: (context, index) => ActivityLogEntryTile(entry: entries[index]),
          );
        },
      ),
    );
  }
}
