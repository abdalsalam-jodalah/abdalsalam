import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../providers/religious_tracking_providers.dart';
import 'religious_history_screen.dart';

class ReligiousHomeScreen extends ConsumerWidget {
  static const routeName = '/religious';

  const ReligiousHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimes = ref.watch(todayPrayerTimesProvider);
    final todayLogs = ref.watch(todayReligiousLogsProvider);
    final logsState = ref.watch(religiousLogsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Religious Module'),
        actions: [
          IconButton(
            tooltip: 'Sync prayer times',
            onPressed: () async {
              final message = await ref.read(religiousLogsControllerProvider.notifier).syncPrayerTimes();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message ?? 'Prayer times synced successfully')),
              );
            },
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () => Navigator.of(context).pushNamed(ReligiousHistoryScreen.routeName),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        key: const ValueKey('religious-home'),
        padding: const EdgeInsets.all(16),
        children: [
          _PrayerTimesSection(prayerTimes: prayerTimes),
          const SizedBox(height: 14),
          Text('Quick Log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _showEntryDialog(
                  context,
                  ref,
                  type: ReligiousEntryType.prayer,
                  defaultTitle: 'Prayer log',
                ),
                icon: const Icon(Icons.mosque_outlined),
                label: const Text('Prayer'),
              ),
              FilledButton.icon(
                onPressed: () => _showEntryDialog(
                  context,
                  ref,
                  type: ReligiousEntryType.quranReading,
                  defaultTitle: 'Quran reading',
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Quran'),
              ),
              FilledButton.icon(
                onPressed: () => _showEntryDialog(
                  context,
                  ref,
                  type: ReligiousEntryType.athkar,
                  defaultTitle: 'Athkar',
                ),
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Athkar'),
              ),
              FilledButton.icon(
                onPressed: () => _showEntryDialog(
                  context,
                  ref,
                  type: ReligiousEntryType.nightPrayer,
                  defaultTitle: 'Night prayer',
                ),
                icon: const Icon(Icons.nights_stay_outlined),
                label: const Text('Night Prayer'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEntryDialog(
                  context,
                  ref,
                  type: ReligiousEntryType.badEvent,
                  defaultTitle: 'Bad event',
                ),
                icon: const Icon(Icons.warning_amber_outlined),
                label: const Text('Bad Event'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Today Logs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (logsState.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (todayLogs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No logs for today yet.'),
              ),
            )
          else
            ...todayLogs.map(
              (item) => Card(
                child: ListTile(
                  leading: Icon(_iconForType(item.type)),
                  title: Text(item.title),
                  subtitle: Text(
                    '${DateFormat('hh:mm a').format(item.loggedAt)} • ${_typeLabel(item.type)}${item.details == null || item.details!.isEmpty ? '' : '\n${item.details}'}',
                  ),
                  isThreeLine: item.details != null && item.details!.isNotEmpty,
                  trailing: Text('x${item.count}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEntryDialog(
    BuildContext context,
    WidgetRef ref, {
    required ReligiousEntryType type,
    required String defaultTitle,
  }) async {
    final titleController = TextEditingController(text: defaultTitle);
    final detailsController = TextEditingController();
    final countController = TextEditingController(text: '1');
    String prayerName = 'fajr';
    bool reminderEnabled = false;
    DateTime reminderAt = DateTime.now().add(const Duration(hours: 1));

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Log ${_typeLabel(type)}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    if (type == ReligiousEntryType.prayer) ...[
                      DropdownButtonFormField<String>(
                        initialValue: prayerName,
                        items: const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']
                            .map((name) => DropdownMenuItem(value: name, child: Text(name.toUpperCase())))
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => prayerName = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Prayer name'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Count / Number'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detailsController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Details (optional)'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add reminder'),
                      value: reminderEnabled,
                      onChanged: (value) => setState(() => reminderEnabled = value),
                    ),
                    if (reminderEnabled)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            initialDate: reminderAt,
                          );
                          if (pickedDate == null || !context.mounted) {
                            return;
                          }
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(reminderAt),
                          );
                          if (pickedTime == null) {
                            return;
                          }
                          setState(() {
                            reminderAt = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text('Reminder: ${DateFormat('yyyy-MM-dd hh:mm a').format(reminderAt)}'),
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
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || !context.mounted) {
      titleController.dispose();
      detailsController.dispose();
      countController.dispose();
      return;
    }

    final count = int.tryParse(countController.text.trim()) ?? 1;

    final error = await ref.read(religiousLogsControllerProvider.notifier).addEntry(
          type: type,
          title: titleController.text.trim().isEmpty ? defaultTitle : titleController.text.trim(),
          count: count <= 0 ? 1 : count,
          details: detailsController.text.trim().isEmpty ? null : detailsController.text.trim(),
          prayerName: type == ReligiousEntryType.prayer ? prayerName : null,
          reminderAt: reminderEnabled ? reminderAt : null,
        );

    titleController.dispose();
    detailsController.dispose();
    countController.dispose();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Log saved successfully')),
    );
  }

  static IconData _iconForType(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return Icons.mosque_outlined;
      case ReligiousEntryType.quranReading:
        return Icons.menu_book_outlined;
      case ReligiousEntryType.badEvent:
        return Icons.warning_amber_outlined;
      case ReligiousEntryType.athkar:
        return Icons.favorite_outline;
      case ReligiousEntryType.nightPrayer:
        return Icons.nights_stay_outlined;
    }
  }

  static String _typeLabel(ReligiousEntryType type) {
    switch (type) {
      case ReligiousEntryType.prayer:
        return 'Prayer';
      case ReligiousEntryType.quranReading:
        return 'Quran Reading';
      case ReligiousEntryType.badEvent:
        return 'Bad Event';
      case ReligiousEntryType.athkar:
        return 'Athkar';
      case ReligiousEntryType.nightPrayer:
        return 'Night Prayer';
    }
  }
}

class _PrayerTimesSection extends StatelessWidget {
  final AsyncValue<PrayerTimesSnapshot> prayerTimes;

  const _PrayerTimesSection({required this.prayerTimes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.10), scheme.surface),
            Color.alphaBlend(scheme.secondary.withValues(alpha: 0.08), scheme.surface),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: prayerTimes.when(
        data: (times) {
          final entries = <MapEntry<String, DateTime>>[
            MapEntry('Fajr', times.fajr),
            MapEntry('Dhuhr', times.dhuhr),
            MapEntry('Asr', times.asr),
            MapEntry('Maghrib', times.maghrib),
            MapEntry('Isha', times.isha),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prayer Times', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Source: quran-radio.com • Updated ${DateFormat('hh:mm a').format(times.fetchedAt)}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in entries)
                    Chip(
                      label: Text('${item.key}: ${DateFormat('hh:mm a').format(item.value)}'),
                    ),
                ],
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text('Could not load prayer times: $error'),
      ),
    );
  }
}
