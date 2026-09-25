import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/validation/validation_utils.dart';
import '../../../data/models/religious/quran_reading.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/async_error_view.dart';
import '../../../shared/widgets/charts/app_line_chart.dart';
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
                result.when(
                  success: (report) =>
                      AppFeedback.showSuccess(context, _legacyImportSummaryMessage(report)),
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
                    child: AppLineChart(points: points),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => AsyncErrorView(
                  error: err,
                  isCompact: true,
                  onRetry: () => ref.invalidate(quranPagesLast7DaysProvider),
                ),
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _QuranReadingDialogContent(ref: ref),
    );
  }
}

class _QuranReadingDialogContent extends StatefulWidget {
  const _QuranReadingDialogContent({required this.ref});

  final WidgetRef ref;

  @override
  State<_QuranReadingDialogContent> createState() => _QuranReadingDialogContentState();
}

class _QuranReadingDialogContentState extends State<_QuranReadingDialogContent> {
  static const String _surahFieldKey = 'surahNumber';
  static const String _ayahToFieldKey = 'ayahTo';
  static const String _pagesFieldKey = 'pagesRead';
  static const String _minutesFieldKey = 'durationMinutes';
  static const int _minSurahNumber = 1;
  static const int _maxSurahNumber = 114;

  final _formKey = GlobalKey<FormState>();
  final surahController = TextEditingController();
  final ayahFromController = TextEditingController();
  final ayahToController = TextEditingController();
  final durationController = TextEditingController();
  final pagesController = TextEditingController();
  final placeController = TextEditingController();
  var memorized = false;
  var isSaving = false;
  Map<String, String> fieldErrors = const <String, String>{};

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

  String? _validateSurah(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Surah number');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Surah number must be a whole number';
    final rangeError = ValidationUtils.numericRange(
      value: parsed,
      fieldName: 'Surah number',
      min: _minSurahNumber,
      max: _maxSurahNumber,
    );
    return rangeError ?? fieldErrors[_surahFieldKey];
  }

  String? _validateAyahFrom(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Ayah from');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Ayah from must be a whole number';
    return ValidationUtils.positiveNumber(value: parsed, fieldName: 'Ayah from');
  }

  String? _validateAyahTo(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Ayah to');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Ayah to must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Ayah to');
    if (positiveError != null) return positiveError;
    final ayahFrom = int.tryParse(ayahFromController.text.trim());
    if (ayahFrom != null && parsed < ayahFrom) {
      return 'Ayah to must be at least ayah from';
    }
    return fieldErrors[_ayahToFieldKey];
  }

  String? _validatePages(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Pages read');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Pages read must be a whole number';
    final rangeError = ValidationUtils.numericRange(value: parsed, fieldName: 'Pages read', min: 0);
    return rangeError ?? fieldErrors[_pagesFieldKey];
  }

  String? _validateMinutes(String? value) {
    final requiredError = ValidationUtils.requiredField(value, 'Minutes spent');
    if (requiredError != null) return requiredError;
    final parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Minutes spent must be a whole number';
    final positiveError = ValidationUtils.positiveNumber(value: parsed, fieldName: 'Minutes spent');
    return positiveError ?? fieldErrors[_minutesFieldKey];
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSaving = true;
      fieldErrors = const <String, String>{};
    });

    final error = await widget.ref.read(quranReadingControllerProvider.notifier).addReading(
          surahNumber: int.parse(surahController.text.trim()),
          ayahFrom: int.parse(ayahFromController.text.trim()),
          ayahTo: int.parse(ayahToController.text.trim()),
          durationMinutes: int.parse(durationController.text.trim()),
          pagesRead: int.parse(pagesController.text.trim()),
          memorized: memorized,
          place: placeController.text.trim().isEmpty ? null : placeController.text.trim(),
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
      title: const Text('Add Quran Reading'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: surahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Surah number (1-114)'),
                validator: _validateSurah,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ayahFromController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ayah from'),
                      validator: _validateAyahFrom,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: ayahToController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Ayah to'),
                      validator: _validateAyahTo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pages read'),
                validator: _validatePages,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes spent'),
                validator: _validateMinutes,
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
