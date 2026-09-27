import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_module_accents.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/health/blood_test.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/entity_tile.dart';
import '../../../shared/widgets/ui/page_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final accent = AppModuleAccents.forModule('health');
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
          children: [
            if (widget.embedded) const PageHeader(title: 'Blood Tests'),
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
                  Wrap(
                    spacing: tokens.spacing.sm,
                    runSpacing: tokens.spacing.sm,
                    children: [
                      Chip(label: Text('Scheduled: ${stats['scheduledCount'] ?? scheduled.length}')),
                      Chip(label: Text('Completed: ${stats['completedCount'] ?? completed.length}')),
                    ],
                  ),
                  if (scheduled.isNotEmpty) ...[
                    const AppSectionHeader(title: 'Upcoming'),
                    for (final test in scheduled) ...[
                      EntityTile(
                        icon: Icons.science_outlined,
                        accentColor: accent,
                        title: test.testType,
                        subtitle: 'Scheduled: ${AppDateFormatter.date(test.scheduledDate)}'
                            '${test.facility != null ? '\n${test.facility}' : ''}'
                            '${test.results.isNotEmpty ? '\n${test.results.length} result(s)' : ''}',
                        subtitleMaxLines: 3,
                        onTap: () => _openForm(test: test),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(test),
                        ),
                      ),
                      SizedBox(height: tokens.spacing.sm),
                    ],
                  ],
                  if (completed.isNotEmpty) ...[
                    const AppSectionHeader(title: 'Completed'),
                    for (final test in completed) ...[
                      EntityTile(
                        icon: Icons.science_outlined,
                        accentColor: accent,
                        title: test.testType,
                        subtitle: 'Completed: ${AppDateFormatter.date(test.completedDate!)}'
                            '${test.facility != null ? '\n${test.facility}' : ''}'
                            '${test.results.isNotEmpty ? '\n${test.results.length} result(s)' : ''}',
                        subtitleMaxLines: 3,
                        onTap: () => _openForm(test: test),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(test),
                        ),
                      ),
                      SizedBox(height: tokens.spacing.sm),
                    ],
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
      appBar: AppBar(title: const Text('Blood Tests')),
      floatingActionButton: fab,
      body: content,
    );
  }
}
