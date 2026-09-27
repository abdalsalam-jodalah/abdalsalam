import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/sleep_providers.dart';
import 'sleep_log_form_screen.dart';

class SleepLogsScreen extends ConsumerStatefulWidget {
  static const routeName = '/sleep/logs';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [SleepScreen] shell.
  final bool embedded;

  const SleepLogsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SleepLogsScreen> createState() => _SleepLogsScreenState();
}

class _SleepLogsScreenState extends ConsumerState<SleepLogsScreen> {
  Future<void> _delete(SleepLog log) async {
    final service = ref.read(sleepLogServiceProvider);
    final result = await service.softDelete(log.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(sleepLogsProvider);
    ref.invalidate(sleepLogStatisticsProvider);
  }

  Future<void> _openForm({SleepLog? log}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => SleepLogFormScreen(log: log)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(sleepLogsProvider);
      ref.invalidate(sleepLogStatisticsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('sleep');
    final logsAsync = ref.watch(sleepLogsProvider);

    final content = logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(sleepLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No sleep logs yet. Tap + to add one.'));
        }

        return ListView(
          children: [
            if (widget.embedded) const PageHeader(title: 'Sleep Logs'),
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
                  for (final log in logs) ...[
                    EntityTile(
                      icon: Icons.bedtime_outlined,
                      accentColor: accent,
                      title: '${(log.duration.inMinutes / 60).toStringAsFixed(1)}h • ${AppDateFormatter.date(log.sleepStart)}',
                      subtitle: '${log.nightWakeCount} wake-up(s)'
                          '${log.notes != null ? '\n${log.notes}' : ''}',
                      subtitleMaxLines: 2,
                      onTap: () => _openForm(log: log),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(log),
                      ),
                    ),
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
      appBar: AppBar(title: const Text('Sleep Logs')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
