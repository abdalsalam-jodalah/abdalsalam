import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/quran_reading.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/chart_widgets.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/quran_reading_providers.dart';
import '../services/quran_legacy_import_report.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Text(
                  'Quran',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Reading',
                  onPressed: () => _showAddDialog(context, ref),
                ),
              ],
            ),
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
                final result = await ref
                    .read(quranReadingControllerProvider.notifier)
                    .importLegacyProgress();
                if (!context.mounted) {
                  return;
                }
                final message = result.when(
                  success: _legacyImportSummaryMessage,
                  failure: (error) =>
                      ref.read(userErrorMessageMapperProvider).toUserMessage(error),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
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
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Add Reading'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranReadingControllerProvider);
    final pagesThisWeek = ref.watch(quranPagesThisWeekProvider);
    final last7Days = ref.watch(quranPagesLast7DaysProvider);
    final allReadings = ref.watch(quranAllReadingsProvider);

    return state.when(
        data: (logs) {
          final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
          final totalMinutes = logs.fold<int>(0, (sum, item) => sum + item.durationMinutes);

          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Color.alphaBlend(scheme.secondary.withValues(alpha: 0.12), scheme.surface),
                      scheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: scheme.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text('Reading Progress', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Today'),
                        Text(
                          '$totalPages pages / $totalMinutes min',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('This week'),
                        Text(
                          pagesThisWeek.when(
                            data: (pages) => '$pages pages',
                            loading: () => '…',
                            error: (_, _) => '-',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (logs.isEmpty)
                EmptyState(
                  title: 'No Quran readings logged yet today',
                  subtitle: 'Add your first reading to start tracking.',
                  actionLabel: 'Add Reading',
                  onAction: () => _showAddDialog(context, ref),
                )
              else
                ...logs.map((log) => _ReadingCard(log: log)),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Pages Read (Last 7 Days)'),
              const SizedBox(height: 8),
              last7Days.when(
                data: (points) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TrendLineChart(points: points),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Could not load chart: $err'),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'History'),
              const SizedBox(height: 8),
              allReadings.when(
                data: (all) {
                  if (all.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No history yet.'),
                    );
                  }
                  final sorted = [...all]..sort((a, b) => b.readAt.compareTo(a.readAt));
                  return Column(children: sorted.map((log) => _ReadingCard(log: log)).toList());
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_QuranReadingResult>(
      context: context,
      builder: (_) => const _QuranReadingDialogContent(),
    );

    if (result == null) return;

    final error = await ref.read(quranReadingControllerProvider.notifier).addReading(
          surahNumber: result.surah,
          ayahFrom: result.ayahFrom,
          ayahTo: result.ayahTo,
          durationMinutes: result.minutes,
          pagesRead: result.pages,
          memorized: result.memorized,
          place: result.place,
        );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(userErrorMessageMapperProvider).toUserMessage(error))),
      );
    }
  }
}

class _QuranReadingResult {
  _QuranReadingResult({
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.pages,
    required this.minutes,
    required this.memorized,
    required this.place,
  });

  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final int pages;
  final int minutes;
  final bool memorized;
  final String? place;
}

class _QuranReadingDialogContent extends StatefulWidget {
  const _QuranReadingDialogContent();

  @override
  State<_QuranReadingDialogContent> createState() => _QuranReadingDialogContentState();
}

class _QuranReadingDialogContentState extends State<_QuranReadingDialogContent> {
  final surahController = TextEditingController();
  final ayahFromController = TextEditingController();
  final ayahToController = TextEditingController();
  final durationController = TextEditingController();
  final pagesController = TextEditingController();
  final placeController = TextEditingController();
  var memorized = false;
  String? error;

  @override
  void dispose() {
    surahController.dispose();
    ayahFromController.dispose();
    ayahToController.dispose();
    durationController.dispose();
    pagesController.dispose();
    placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Quran Reading'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: surahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Surah number (1-114)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ayahFromController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayah from'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ayahToController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ayah to'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pagesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pages read'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minutes spent'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: placeController,
              decoration: const InputDecoration(labelText: 'Place (optional)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Memorized this range'),
              value: memorized,
              onChanged: (value) => setState(() => memorized = value),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final surah = int.tryParse(surahController.text.trim()) ?? 0;
            final ayahFrom = int.tryParse(ayahFromController.text.trim()) ?? 0;
            final ayahTo = int.tryParse(ayahToController.text.trim()) ?? 0;
            final pages = int.tryParse(pagesController.text.trim()) ?? 0;
            final minutes = int.tryParse(durationController.text.trim()) ?? 0;
            setState(() {
              if (surah < 1 || surah > 114) {
                error = 'Surah number must be between 1 and 114';
              } else if (ayahTo < ayahFrom) {
                error = 'Ayah to must be >= ayah from';
              } else if (minutes <= 0) {
                error = 'Minutes must be greater than 0';
              } else if (pages < 0) {
                error = 'Pages cannot be negative';
              } else {
                error = null;
              }
            });
            if (error == null) {
              Navigator.of(context).pop(
                _QuranReadingResult(
                  surah: surah,
                  ayahFrom: ayahFrom,
                  ayahTo: ayahTo,
                  pages: pages,
                  minutes: minutes,
                  memorized: memorized,
                  place: placeController.text.trim().isEmpty ? null : placeController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.log});

  final QuranReading log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.menu_book_outlined, color: scheme.secondary, size: 20),
        ),
        title: Text(
          log.surahNumber == 0
              ? '${log.pagesRead} pages'
              : 'Surah ${log.surahNumber}: ${log.ayahFrom}-${log.ayahTo}',
        ),
        subtitle: Text(
          '${log.pagesRead} pages • ${log.durationMinutes} min'
          '${log.place != null ? ' • ${log.place}' : ''}'
          ' • ${DateFormat('MMM d, hh:mm a').format(log.readAt)}'
          '${log.memorized ? ' • Memorized' : ''}',
        ),
        trailing: log.memorized
            ? Icon(Icons.bookmark, color: scheme.secondary)
            : null,
      ),
    );
  }
}
