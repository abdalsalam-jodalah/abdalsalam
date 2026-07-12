import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/prayer_times_snapshot.dart';
import '../../../data/models/religious/religious_entry.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/athkar_providers.dart';
import '../providers/prayer_providers.dart';
import '../providers/quran_reading_providers.dart';
import '../providers/religious_tracking_providers.dart';
import 'athkar_screen.dart';
import 'bad_practice_screen.dart';
import 'prayer_logs_screen.dart';
import 'quran_reading_screen.dart';
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
          const SizedBox(height: 16),
          const _StatsRow(),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Quick Log',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(QuranReadingScreen.routeName),
              child: const Text('Quran Log'),
            ),
          ),
          const SizedBox(height: 10),
          _QuickLogGrid(),
          const SizedBox(height: 20),
          _SectionHeader(title: "Today's Logs"),
          const SizedBox(height: 8),
          if (logsState.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (todayLogs.isEmpty)
            EmptyState(
              title: 'No logs for today yet',
              subtitle: 'Use quick log above to record a prayer, Quran reading, athkar, or event.',
              actionLabel: 'Log Prayer',
              onAction: () => Navigator.of(context).pushNamed(PrayerLogsScreen.routeName),
            )
          else
            ...todayLogs.map(
              (item) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _iconForType(item.type),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
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

  static Future<void> _showEntryDialog(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        ?trailing,
      ],
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(religiousStreakProvider);
    final prayersToday = ref.watch(prayerCountProvider);
    final athkarToday = ref.watch(athkarTodayCountProvider);
    final quranPagesWeek = ref.watch(quranPagesThisWeekProvider);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Streak',
            value: streak.maybeWhen(data: (v) => '$v d', orElse: () => '…'),
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Prayers Today',
            value: '$prayersToday',
            icon: Icons.mosque_outlined,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Athkar Today',
            value: '$athkarToday',
            icon: Icons.favorite_outline,
            color: scheme.tertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Quran (wk)',
            value: quranPagesWeek.maybeWhen(data: (v) => '$v p', orElse: () => '…'),
            icon: Icons.menu_book_outlined,
            color: scheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _QuickLogTile(
          label: 'Prayer',
          icon: Icons.mosque_outlined,
          color: scheme.primary,
          onTap: () => Navigator.of(context).pushNamed(PrayerLogsScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Quran',
          icon: Icons.menu_book_outlined,
          color: scheme.secondary,
          onTap: () => Navigator.of(context).pushNamed(QuranReadingScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Athkar',
          icon: Icons.favorite_outline,
          color: scheme.tertiary,
          onTap: () => Navigator.of(context).pushNamed(AthkarScreen.routeName),
        ),
        _QuickLogTile(
          label: 'Night Prayer',
          icon: Icons.nights_stay_outlined,
          color: scheme.primary,
          onTap: () => ReligiousHomeScreen._showEntryDialog(
            context,
            ref,
            type: ReligiousEntryType.nightPrayer,
            defaultTitle: 'Night prayer',
          ),
        ),
        _QuickLogTile(
          label: 'Bad Event',
          icon: Icons.warning_amber_outlined,
          color: scheme.error,
          onTap: () => Navigator.of(context).pushNamed(BadPracticeScreen.routeName),
        ),
      ],
    );
  }
}

class _QuickLogTile extends StatelessWidget {
  const _QuickLogTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
              Text('Source: ${times.sourceUrl} • Updated ${DateFormat('hh:mm a').format(times.fetchedAt)}'),
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
