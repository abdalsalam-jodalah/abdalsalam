import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
            return const Center(
              child: Text('No Quran logs yet. Add your first progress entry.'),
            );
          }

          final totalPages = logs.fold<int>(0, (sum, item) => sum + item.pagesRead);
          final totalMinutes = logs.fold<int>(0, (sum, item) => sum + item.minutesSpent);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today total'),
                      Text('$totalPages pages / $totalMinutes min'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...logs.map(
                (log) => Card(
                  child: ListTile(
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
    final pagesController = TextEditingController();
    final minutesController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Quran Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pagesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pages read'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes spent'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !context.mounted) {
      pagesController.dispose();
      minutesController.dispose();
      return;
    }

    final pages = int.tryParse(pagesController.text.trim()) ?? 0;
    final minutes = int.tryParse(minutesController.text.trim()) ?? 0;

    final message = await ref.read(quranProgressControllerProvider.notifier).addProgress(
          pagesRead: pages,
          minutesSpent: minutes,
        );

    pagesController.dispose();
    minutesController.dispose();

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
