import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/bad_practice_providers.dart';

class BadPracticeScreen extends ConsumerWidget {
  const BadPracticeScreen({super.key});

  static const String routeName = '/religious/bad-practice';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(badPracticeLogControllerProvider);
    final weeklyTrend = ref.watch(badPracticeWeeklyTrendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bad Practice Log')),
      body: state.when(
        data: (logs) {
          final now = DateTime.now();
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final thisWeekCount =
              logs.where((item) => !item.occurredAt.isBefore(startOfWeek)).length;
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_outlined, color: scheme.error, size: 20),
                            const SizedBox(height: 8),
                            Text('Total entries', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text('${logs.length}', style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.calendar_today_outlined, color: scheme.error, size: 20),
                            const SizedBox(height: 8),
                            Text('This week', style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text('$thisWeekCount', style: Theme.of(context).textTheme.headlineSmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Weekly Trend (Last 8 Weeks)'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TrendLineChart(points: weeklyTrend),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'History'),
              const SizedBox(height: 8),
              if (logs.isEmpty)
                EmptyState(
                  title: 'No entries yet',
                  subtitle: 'Log a bad practice event to start tracking patterns over time.',
                  actionLabel: 'Log Entry',
                  onAction: () => _showAddDialog(context, ref),
                ),
              ...logs.map(
                (log) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_outlined, color: scheme.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      log.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, hh:mm a').format(log.occurredAt),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        if (log.feelingBefore != null || log.feelingAfter != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Feeling: ${log.feelingBefore ?? '-'} → ${log.feelingAfter ?? '-'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (log.consequences != null && log.consequences!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Consequences: ${log.consequences}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (log.notes != null && log.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(log.notes!, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final feelingBeforeController = TextEditingController();
    final feelingAfterController = TextEditingController();
    final consequencesController = TextEditingController();
    final notesController = TextEditingController();
    DateTime occurredAt = DateTime.now();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        String? titleError;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Log Bad Practice'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'What happened',
                      errorText: titleError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                        initialDate: occurredAt,
                      );
                      if (pickedDate == null || !context.mounted) {
                        return;
                      }
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(occurredAt),
                      );
                      if (pickedTime == null) {
                        return;
                      }
                      setState(() {
                        occurredAt = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(DateFormat('MMM d, yyyy hh:mm a').format(occurredAt)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feelingBeforeController,
                    decoration: const InputDecoration(labelText: 'Feeling before (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feelingAfterController,
                    decoration: const InputDecoration(labelText: 'Feeling after (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: consequencesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Consequences (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    titleError = titleController.text.trim().isEmpty
                        ? 'This field is required'
                        : null;
                  });
                  if (titleError == null) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldSave != true || !context.mounted) {
      return;
    }

    final message = await ref.read(badPracticeLogControllerProvider.notifier).logEvent(
          title: titleController.text.trim(),
          occurredAt: occurredAt,
          feelingBefore: feelingBeforeController.text.trim().isEmpty
              ? null
              : feelingBeforeController.text.trim(),
          feelingAfter: feelingAfterController.text.trim().isEmpty
              ? null
              : feelingAfterController.text.trim(),
          consequences: consequencesController.text.trim().isEmpty
              ? null
              : consequencesController.text.trim(),
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
