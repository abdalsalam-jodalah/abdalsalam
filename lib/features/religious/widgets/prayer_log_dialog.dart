import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/religious/prayer_log.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/prayer_providers.dart';
import '../providers/religious_tracking_providers.dart';

class PrayerLogResult {
  final PrayerName prayer;
  final DateTime prayedAt;
  final bool overrideOnTime;
  final bool manualOnTime;
  final String? notes;

  const PrayerLogResult({
    required this.prayer,
    required this.prayedAt,
    required this.overrideOnTime,
    required this.manualOnTime,
    required this.notes,
  });
}

Future<PrayerLogResult?> showPrayerLogDialog(
  BuildContext context,
  WidgetRef ref, {
  required DateTime? initialScheduledAt,
  PrayerName initialPrayer = PrayerName.fajr,
}) {
  return showDialog<PrayerLogResult>(
    context: context,
    builder: (_) =>
        PrayerLogDialogContent(ref: ref, initialScheduledAt: initialScheduledAt, initialPrayer: initialPrayer),
  );
}

class PrayerLogDialogContent extends StatefulWidget {
  final WidgetRef ref;
  final DateTime? initialScheduledAt;
  final PrayerName initialPrayer;

  const PrayerLogDialogContent({
    super.key,
    required this.ref,
    required this.initialScheduledAt,
    this.initialPrayer = PrayerName.fajr,
  });

  @override
  State<PrayerLogDialogContent> createState() => _PrayerLogDialogContentState();
}

class _PrayerLogDialogContentState extends State<PrayerLogDialogContent> {
  static const String _voluntaryHint =
      'A voluntary prayer you offer for God. It does not count toward the five daily prayers.';

  late PrayerName selectedPrayer = widget.initialPrayer;
  DateTime prayedAt = DateTime.now();
  bool overrideOnTime = false;
  bool manualOnTime = true;
  final notesController = TextEditingController();
  DateTime? scheduledAt;

  @override
  void initState() {
    super.initState();
    scheduledAt = widget.initialScheduledAt;
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _refreshScheduled(PrayerName prayer) async {
    if (prayer.isVoluntary) {
      setState(() => scheduledAt = null);
      return;
    }
    try {
      final snapshot = await widget.ref.read(todayPrayerTimesProvider.future);
      if (!mounted) return;
      setState(() => scheduledAt = scheduledTimeForPrayer(prayer, snapshot));
    } catch (error, stackTrace) {
      widget.ref.read(loggerProvider).error(
            'Could not resolve scheduled prayer time for $prayer in the add-log dialog.',
            error: error,
            stackTrace: stackTrace,
          );
      if (!mounted) return;
      setState(() => scheduledAt = null);
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      PrayerLogResult(
        prayer: selectedPrayer,
        prayedAt: prayedAt,
        overrideOnTime: selectedPrayer.isObligatory && overrideOnTime,
        manualOnTime: manualOnTime,
        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final delta = scheduledAt == null ? null : prayedAt.difference(scheduledAt!);

    return AppFormDialog(
      title: 'Add Prayer Log',
      submitLabel: 'Save',
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<PrayerName>(
            initialValue: selectedPrayer,
            items: PrayerName.values
                .map((prayer) => DropdownMenuItem(value: prayer, child: Text(prayer.label)))
                .toList(growable: false),
            onChanged: (value) async {
              if (value != null) {
                setState(() => selectedPrayer = value);
                await _refreshScheduled(value);
              }
            },
            decoration: const InputDecoration(labelText: 'Prayer'),
          ),
          SizedBox(height: tokens.spacing.md),
          if (selectedPrayer.isVoluntary)
            Text(_voluntaryHint, key: const ValueKey('voluntary-hint'), style: theme.textTheme.bodyMedium),
          if (scheduledAt != null)
            Text('Scheduled: ${AppDateFormatter.time(scheduledAt!)}', style: theme.textTheme.bodyMedium),
          SizedBox(height: tokens.spacing.sm),
          DateTimeField(
            label: 'Prayed at',
            mode: DateTimeFieldMode.time,
            value: prayedAt,
            onChanged: (value) => setState(() => prayedAt = value ?? prayedAt),
          ),
          if (delta != null) ...[
            SizedBox(height: tokens.spacing.sm),
            Text(
              delta.inMinutes.abs() < 1
                  ? 'On time'
                  : delta.isNegative
                      ? '${delta.inMinutes.abs()} min before adhan'
                      : '${delta.inMinutes.abs()} min after adhan',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          SizedBox(height: tokens.spacing.md),
          if (selectedPrayer.isObligatory)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manually override on-time status'),
              value: overrideOnTime,
              onChanged: (value) => setState(() => overrideOnTime = value),
            ),
          if (selectedPrayer.isObligatory && overrideOnTime)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('On time'),
              value: manualOnTime,
              onChanged: (value) => setState(() => manualOnTime = value),
            ),
          TextField(
            controller: notesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
        ],
      ),
    );
  }
}
