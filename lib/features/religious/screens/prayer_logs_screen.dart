import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/prayer_log.dart';
import '../providers/prayer_providers.dart';
import 'quran_progress_screen.dart';

class PrayerLogsScreen extends ConsumerWidget {
  const PrayerLogsScreen({super.key});

  static const String routeName = '/religious/prayers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(prayerLogsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Logs'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(QuranProgressScreen.routeName);
            },
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Quran'),
          ),
        ],
      ),
      body: logsState.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No logs yet. Add your first prayer log.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                child: ListTile(
                  title: Text(log.prayerName.name.toUpperCase()),
                  subtitle: Text(
                    DateFormat('hh:mm a').format(log.prayedAt),
                  ),
                  trailing: Icon(
                    log.onTime ? Icons.check_circle : Icons.schedule,
                    color: log.onTime
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Add Log'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    PrayerName selectedPrayer = PrayerName.fajr;
    bool onTime = true;
    final notesController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Prayer Log'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PrayerName>(
                    initialValue: selectedPrayer,
                    items: PrayerName.values
                        .map(
                          (prayer) => DropdownMenuItem(
                            value: prayer,
                            child: Text(prayer.name.toUpperCase()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedPrayer = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('On time'),
                    value: onTime,
                    onChanged: (value) => setState(() => onTime = value),
                  ),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
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
      },
    );

    if (shouldSave != true || !context.mounted) {
      notesController.dispose();
      return;
    }

    final message = await ref.read(prayerLogsControllerProvider.notifier).addPrayer(
          prayer: selectedPrayer,
          onTime: onTime,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

    notesController.dispose();

    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
