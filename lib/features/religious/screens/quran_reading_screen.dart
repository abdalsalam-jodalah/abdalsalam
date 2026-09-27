import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/widgets/ui/app_section_header.dart';
import '../../../shared/widgets/ui/page_header.dart';
import '../providers/quran_reading_providers.dart';
import '../services/quran_legacy_import_report.dart';
import '../widgets/quran_reading_dialog.dart';
import '../widgets/quran_reading_progress_card.dart';
import '../widgets/quran_reading_tile.dart';

const String _legacyImportedCountLabel = 'Imported';
const String _legacyImportSkippedCountLabel = 'skipped';

String _legacyImportSummaryMessage(QuranLegacyImportReport report) {
  return '$_legacyImportedCountLabel ${report.importedCount}, '
      '$_legacyImportSkippedCountLabel ${report.skippedLegacyIds.length}';
}

class QuranReadingScreen extends ConsumerWidget {
  /// When true, renders without its own [Scaffold]/[AppBar]/FAB for
  /// embedding inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const QuranReadingScreen({super.key, this.embedded = false});

  static const String routeName = '/religious/quran-reading';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (embedded) {
      return Column(
        children: [
          PageHeader(
            title: 'Quran',
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Reading',
                onPressed: () => showQuranReadingDialog(context, ref),
              ),
            ],
          ),
          Expanded(child: _buildBody(context, ref)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Reading'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'import') {
                final result = await ref.read(quranReadingControllerProvider.notifier).importLegacyProgress();
                if (!context.mounted) {
                  return;
                }
                result.when(
                  success: (report) => AppFeedback.showSuccess(context, _legacyImportSummaryMessage(report)),
                  failure: (error) => AppFeedback.showError(context, error),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'import',
                child: Text('Import legacy Quran progress'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuranReadingDialog(context, ref),
        label: const Text('Add Reading'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final tokens = AppThemeTokens.of(context);
    final state = ref.watch(quranReadingControllerProvider);
    final pagesThisWeek = ref.watch(quranPagesThisWeekProvider);
    final last7Days = ref.watch(quranPagesLast7DaysProvider);
    final allReadings = ref.watch(quranAllReadingsProvider);

    return state.when(
      data: (logs) {
        final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
        final totalMinutes = logs.fold<int>(0, (sum, item) => sum + item.durationMinutes);

        return ListView(
          padding: EdgeInsets.all(tokens.spacing.lg),
          children: [
            QuranReadingProgressCard(
              totalPages: totalPages,
              totalMinutes: totalMinutes,
              pagesThisWeek: pagesThisWeek,
            ),
            SizedBox(height: tokens.spacing.md),
            if (logs.isEmpty)
              EmptyState(
                title: 'No Quran readings logged yet today',
                subtitle: 'Add your first reading to start tracking.',
                actionLabel: 'Add Reading',
                onAction: () => showQuranReadingDialog(context, ref),
              )
            else
              for (final log in logs)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                  child: QuranReadingTile(log: log),
                ),
            AppSectionHeader(title: 'Pages Read (Last 7 Days)'),
            last7Days.when(
              data: (points) => AppCard(child: AppLineChart(points: points)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncErrorView(
                error: err,
                isCompact: true,
                onRetry: () => ref.invalidate(quranPagesLast7DaysProvider),
              ),
            ),
            AppSectionHeader(title: 'History'),
            allReadings.when(
              data: (all) {
                if (all.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
                    child: Text('No history yet.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                final sorted = [...all]..sort((a, b) => b.readAt.compareTo(a.readAt));
                return Column(
                  children: [
                    for (final log in sorted)
                      Padding(
                        padding: EdgeInsets.only(bottom: tokens.spacing.sm),
                        child: QuranReadingTile(log: log),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AsyncErrorView(
                error: err,
                isCompact: true,
                onRetry: () => ref.invalidate(quranAllReadingsProvider),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => AsyncErrorView(
        error: err,
        onRetry: () => ref.invalidate(quranReadingControllerProvider),
      ),
    );
  }
}
