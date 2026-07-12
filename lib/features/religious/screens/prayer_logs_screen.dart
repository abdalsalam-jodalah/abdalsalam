import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/religious/prayer_log.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/prayer_providers.dart';
import '../providers/religious_tracking_providers.dart';
import '../widgets/prayer_calendar_heatmap.dart';
import '../widgets/prayer_streak_widget.dart';
import 'quran_progress_screen.dart';

class PrayerLogsScreen extends ConsumerWidget {
  /// When true, renders without its own [Scaffold]/[AppBar]/FAB for
  /// embedding inside the tabbed [ReligiousScreen] shell.
  final bool embedded;

  const PrayerLogsScreen({super.key, this.embedded = false});

  static const String routeName = '/religious/prayers';

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
                  'Prayers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: 'Quran progress',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(QuranProgressScreen.routeName),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Log',
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
      body: _buildBody(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Add Log'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(prayerLogsControllerProvider);
    final allLogsState = ref.watch(prayerAllLogsProvider);
    final streak = ref.watch(religiousStreakProvider);

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          streak.maybeWhen(
            data: (value) => PrayerStreakWidget(streakDays: value),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          allLogsState.when(
            data: (allLogs) => _StatsSummaryRow(allLogs: allLogs),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Text('Could not load stats: $err'),
          ),
          const SizedBox(height: 16),
          allLogsState.when(
            data: (allLogs) => PrayerCalendarHeatmap(
              dailyCompletions: _dailyCompletions(allLogs),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Could not load heatmap: $err'),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Today'),
          const SizedBox(height: 8),
          logsState.when(
            data: (logs) => logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No prayer logs for today yet.'),
                  )
                : Column(children: logs.map((log) => _PrayerLogCard(log: log)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'History'),
          const SizedBox(height: 8),
          allLogsState.when(
            data: (allLogs) {
              if (allLogs.isEmpty) {
                return EmptyState(
                  title: 'No prayer logs yet',
                  subtitle: 'Add your first prayer log to start tracking.',
                  actionLabel: 'Add Log',
                  onAction: () => _showAddDialog(context, ref),
                );
              }
              final sorted = [...allLogs]..sort((a, b) => b.prayedAt.compareTo(a.prayedAt));
              return Column(
                children: sorted.map((log) => _PrayerLogCard(log: log)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
          ),
        ],
      );
  }

  static Map<DateTime, int> _dailyCompletions(List<PrayerLog> logs) {
    final map = <DateTime, int>{};
    for (final log in logs) {
      final day = DateTime(log.prayedAt.year, log.prayedAt.month, log.prayedAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  static String _deltaLabel(PrayerLog log) {
    final delta = log.prayedAt.difference(log.scheduledAt!);
    if (delta.inMinutes.abs() < 1) {
      return 'On time';
    }
    final minutes = delta.inMinutes.abs();
    return delta.isNegative
        ? '$minutes min before ${_prayerLabel(log.prayerName)}'
        : '$minutes min after ${_prayerLabel(log.prayerName)}';
  }

  static String _prayerLabel(PrayerName prayer) {
    return switch (prayer) {
      PrayerName.fajr => 'Fajr',
      PrayerName.dhuhr => 'Dhuhr',
      PrayerName.asr => 'Asr',
      PrayerName.maghrib => 'Maghrib',
      PrayerName.isha => 'Isha',
    };
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    PrayerName selectedPrayer = PrayerName.fajr;
    DateTime prayedAt = DateTime.now();
    bool overrideOnTime = false;
    bool manualOnTime = true;
    final notesController = TextEditingController();

    DateTime? scheduledAt;
    try {
      final snapshot = await ref.read(todayPrayerTimesProvider.future);
      scheduledAt = scheduledTimeForPrayer(selectedPrayer, snapshot);
    } catch (_) {
      scheduledAt = null;
    }

    if (!context.mounted) {
      notesController.dispose();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final delta = scheduledAt == null ? null : prayedAt.difference(scheduledAt!);

            Future<void> refreshScheduled(PrayerName prayer) async {
              try {
                final snapshot = await ref.read(todayPrayerTimesProvider.future);
                setState(() => scheduledAt = scheduledTimeForPrayer(prayer, snapshot));
              } catch (_) {
                setState(() => scheduledAt = null);
              }
            }

            return AlertDialog(
              title: const Text('Add Prayer Log'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          refreshScheduled(value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Prayer'),
                    ),
                    const SizedBox(height: 12),
                    if (scheduledAt != null)
                      Text('Scheduled: ${DateFormat('hh:mm a').format(scheduledAt!)}'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(prayedAt),
                        );
                        if (pickedTime == null) {
                          return;
                        }
                        setState(() {
                          prayedAt = DateTime(
                            prayedAt.year,
                            prayedAt.month,
                            prayedAt.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text('Prayed at: ${DateFormat('hh:mm a').format(prayedAt)}'),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        delta.inMinutes.abs() < 1
                            ? 'On time'
                            : delta.isNegative
                                ? '${delta.inMinutes.abs()} min before adhan'
                                : '${delta.inMinutes.abs()} min after adhan',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Manually override on-time status'),
                      value: overrideOnTime,
                      onChanged: (value) => setState(() => overrideOnTime = value),
                    ),
                    if (overrideOnTime)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('On time'),
                        value: manualOnTime,
                        onChanged: (value) => setState(() => manualOnTime = value),
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
          onTimeOverride: overrideOnTime ? manualOnTime : null,
          prayedAt: prayedAt,
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

class _StatsSummaryRow extends StatelessWidget {
  const _StatsSummaryRow({required this.allLogs});

  final List<PrayerLog> allLogs;

  @override
  Widget build(BuildContext context) {
    final onTimeCount = allLogs.where((log) => log.onTime).length;
    final onTimePercent = allLogs.isEmpty ? 0 : ((onTimeCount / allLogs.length) * 100).round();
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Logs',
            value: '${allLogs.length}',
            icon: Icons.mosque_outlined,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'On Time',
            value: '$onTimePercent%',
            icon: Icons.check_circle_outline,
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _PrayerLogCard extends StatelessWidget {
  const _PrayerLogCard({required this.log});

  final PrayerLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.mosque_outlined, color: scheme.primary, size: 20),
        ),
        title: Text(
          '${log.prayerName.name.toUpperCase()} • ${DateFormat('MMM d').format(log.prayedAt)}',
        ),
        subtitle: Text(
          '${DateFormat('hh:mm a').format(log.prayedAt)}'
          '${log.scheduledAt != null ? ' • ${PrayerLogsScreen._deltaLabel(log)}' : ''}',
        ),
        trailing: Icon(
          log.onTime ? Icons.check_circle : Icons.schedule,
          color: log.onTime ? scheme.primary : scheme.tertiary,
        ),
      ),
    );
  }
}
