import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
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
        error: (err, _) => AsyncErrorView(
          error: err,
          onRetry: () => ref.invalidate(badPracticeLogControllerProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log Entry'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BadPracticeDialogContent(ref: ref),
    );
  }
}

class _BadPracticeDialogContent extends StatefulWidget {
  const _BadPracticeDialogContent({required this.ref});

  final WidgetRef ref;

  @override
  State<_BadPracticeDialogContent> createState() => _BadPracticeDialogContentState();
}

class _BadPracticeDialogContentState extends State<_BadPracticeDialogContent> {
  static const String _titleFieldKey = 'title';

  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final feelingBeforeController = TextEditingController();
  final feelingAfterController = TextEditingController();
  final consequencesController = TextEditingController();
  final notesController = TextEditingController();
  DateTime occurredAt = DateTime.now();
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

  @override
  void dispose() {
    titleController.dispose();
    feelingBeforeController.dispose();
    feelingAfterController.dispose();
    consequencesController.dispose();
    notesController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'What happened');
    return requiredError ?? fieldErrors[_titleFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(badPracticeLogControllerProvider.notifier).logEvent(
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

    if (!mounted) return;

    if (error != null) {
      setState(() {
        isSaving = false;
        fieldErrors = error is ValidationError ? error.fieldErrors : const <String, String>{};
      });
      _formKey.currentState!.validate();
      AppFeedback.showError(context, error);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Bad Practice'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'What happened'),
              validator: _validateTitle,
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
                if (pickedTime == null || !mounted) {
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
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
