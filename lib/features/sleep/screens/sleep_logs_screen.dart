import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
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

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sleep Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ...logs.map((log) {
              final hours = log.duration.inMinutes / 60;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: Text('${hours.toStringAsFixed(1)}h • ${_formatDate(log.sleepStart)}'),
                  subtitle: Text(
                    '${log.nightWakeCount} wake-up(s)'
                    '${log.notes != null ? '\n${log.notes}' : ''}',
                  ),
                  isThreeLine: log.notes != null,
                  onTap: () => _openForm(log: log),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(log),
                  ),
                ),
              );
            }),
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
      appBar: AppBar(title: const Text('Sleep Logs')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
