import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/app_providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/quran_providers.dart';

class QuranProgressScreen extends ConsumerWidget {
  const QuranProgressScreen({super.key});

  static const String routeName = '/religious/quran';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranProgressControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quran Progress')),
      body: state.when(
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              title: 'No Quran logs yet',
              subtitle: 'Add your first progress entry to start tracking.',
              actionLabel: 'Add Progress',
              onAction: () => _showAddDialog(context, ref),
            );
          }

          final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
          final totalMinutes = logs.fold<int>(0, (sum, item) => sum + item.minutesSpent);
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.menu_book_outlined, color: scheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Today total'),
                        ],
                      ),
                      Text(
                        '$totalPages pages / $totalMinutes min',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...logs.map(
                (log) => Card(
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
                    title: Text('${log.pagesRead} pages'),
                    subtitle: Text(
                      '${log.minutesSpent} min - ${DateFormat('hh:mm a').format(log.loggedAt)}',
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
        label: const Text('Add Progress'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_QuranProgressResult>(
      context: context,
      builder: (_) => const _QuranProgressDialogContent(),
    );

    if (result == null) return;

    final error = await ref.read(quranProgressControllerProvider.notifier).addProgress(
          pagesRead: result.pages,
          minutesSpent: result.minutes,
        );

    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(userErrorMessageMapperProvider).toUserMessage(error))),
      );
    }
  }
}

class _QuranProgressResult {
  _QuranProgressResult(this.pages, this.minutes);

  final int pages;
  final int minutes;
}

class _QuranProgressDialogContent extends StatefulWidget {
  const _QuranProgressDialogContent();

  @override
  State<_QuranProgressDialogContent> createState() => _QuranProgressDialogContentState();
}

class _QuranProgressDialogContentState extends State<_QuranProgressDialogContent> {
  final pagesController = TextEditingController();
  final minutesController = TextEditingController();
  String? pagesError;
  String? minutesError;

  @override
  void dispose() {
    pagesController.dispose();
    minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Quran Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: pagesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Pages read',
              errorText: pagesError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minutes spent',
              errorText: minutesError,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final pages = int.tryParse(pagesController.text.trim()) ?? 0;
            final minutes = int.tryParse(minutesController.text.trim()) ?? 0;
            setState(() {
              pagesError = pages <= 0 ? 'Pages must be greater than 0' : null;
              minutesError = minutes <= 0 ? 'Minutes must be greater than 0' : null;
            });
            if (pagesError == null && minutesError == null) {
              Navigator.of(context).pop(_QuranProgressResult(pages, minutes));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
