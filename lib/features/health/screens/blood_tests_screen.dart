import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/health/blood_test.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../providers/health_providers.dart';
import 'blood_test_form_screen.dart';

class BloodTestsScreen extends ConsumerStatefulWidget {
  static const routeName = '/health/blood-tests';

  /// When true, renders without its own [Scaffold]/[AppBar] for embedding
  /// inside the tabbed [HealthScreen] shell.
  final bool embedded;

  const BloodTestsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<BloodTestsScreen> createState() => _BloodTestsScreenState();
}

class _BloodTestsScreenState extends ConsumerState<BloodTestsScreen> {
  Future<void> _delete(BloodTest test) async {
    final service = ref.read(bloodTestServiceProvider);
    final result = await service.softDelete(test.id);
    if (!mounted) return;
    if (result.isFailure) {
      AppFeedback.showError(context, result.error!);
      return;
    }
    ref.invalidate(bloodTestsProvider);
    ref.invalidate(bloodTestStatisticsProvider);
  }

  Future<void> _openForm({BloodTest? test}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => BloodTestFormScreen(test: test)),
    );
    if (!mounted) return;
    if (saved == true) {
      ref.invalidate(bloodTestsProvider);
      ref.invalidate(bloodTestStatisticsProvider);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(bloodTestsProvider);
    final statsAsync = ref.watch(bloodTestStatisticsProvider);

    final content = testsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        error: error,
        onRetry: () => ref.invalidate(bloodTestsProvider),
      ),
      data: (tests) {
        if (tests.isEmpty) {
          return const Center(child: Text('No blood tests logged yet. Tap + to add one.'));
        }

        final stats = statsAsync.value ?? const {};
        final scheduled = tests.where((t) => t.completedDate == null).toList()
          ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
        final completed = tests.where((t) => t.completedDate != null).toList()
          ..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Blood Tests',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Scheduled: ${stats['scheduledCount'] ?? scheduled.length}')),
                Chip(label: Text('Completed: ${stats['completedCount'] ?? completed.length}')),
              ],
            ),
            const SizedBox(height: 16),
            if (scheduled.isNotEmpty) ...[
              Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...scheduled.map((test) => _BloodTestCard(
                    test: test,
                    dateLabel: 'Scheduled: ${_formatDate(test.scheduledDate)}',
                    onTap: () => _openForm(test: test),
                    onDelete: () => _delete(test),
                  )),
              const SizedBox(height: 16),
            ],
            if (completed.isNotEmpty) ...[
              Text('Completed', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...completed.map((test) => _BloodTestCard(
                    test: test,
                    dateLabel: 'Completed: ${_formatDate(test.completedDate!)}',
                    onTap: () => _openForm(test: test),
                    onDelete: () => _delete(test),
                  )),
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
      appBar: AppBar(title: const Text('Blood Tests')),
      floatingActionButton: fab,
      body: content,
    );
  }
}

class _BloodTestCard extends StatelessWidget {
  final BloodTest test;
  final String dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BloodTestCard({
    required this.test,
    required this.dateLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.science_outlined),
        title: Text(test.testType),
        subtitle: Text(
          '$dateLabel'
          '${test.facility != null ? '\n${test.facility}' : ''}'
          '${test.results.isNotEmpty ? '\n${test.results.length} result(s)' : ''}',
        ),
        isThreeLine: test.facility != null || test.results.isNotEmpty,
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
