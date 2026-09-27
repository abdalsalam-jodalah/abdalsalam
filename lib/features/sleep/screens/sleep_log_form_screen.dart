import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/date_time_field.dart';
import '../providers/sleep_providers.dart';
import '../services/sleep_log_service.dart';

const _sleepEndBeforeStartMessage = 'Sleep end must be after sleep start.';

class SleepLogFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/sleep/logs/form';
  final SleepLog? log;

  const SleepLogFormScreen({super.key, this.log});

  @override
  ConsumerState<SleepLogFormScreen> createState() => _SleepLogFormScreenState();
}

class _SleepLogFormScreenState extends ConsumerState<SleepLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feelingBeforeSleepNoteController = TextEditingController();
  final _feelingOnWakeupNoteController = TextEditingController();
  final _feelingDuringDayNoteController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _sleepStart;
  late DateTime _sleepEnd;
  late int _nightWakeCount;
  int? _feelingBeforeSleep;
  int? _feelingOnWakeup;
  int? _feelingDuringDay;
  DateTime? _lastCaffeineTime;
  late final SleepLogService _service;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _service = ref.read(sleepLogServiceProvider);

    if (widget.log != null) {
      final log = widget.log!;
      _sleepStart = log.sleepStart;
      _sleepEnd = log.sleepEnd;
      _nightWakeCount = log.nightWakeCount;
      _feelingBeforeSleep = log.feelingBeforeSleep;
      _feelingBeforeSleepNoteController.text = log.feelingBeforeSleepNote ?? '';
      _feelingOnWakeup = log.feelingOnWakeup;
      _feelingOnWakeupNoteController.text = log.feelingOnWakeupNote ?? '';
      _feelingDuringDay = log.feelingDuringDay;
      _feelingDuringDayNoteController.text = log.feelingDuringDayNote ?? '';
      _lastCaffeineTime = log.lastCaffeineTime;
      _notesController.text = log.notes ?? '';
    } else {
      final now = DateTime.now();
      _sleepStart = DateTime(now.year, now.month, now.day - 1, 23, 0);
      _sleepEnd = DateTime(now.year, now.month, now.day, 7, 0);
      _nightWakeCount = 0;
    }
  }

  @override
  void dispose() {
    _feelingBeforeSleepNoteController.dispose();
    _feelingOnWakeupNoteController.dispose();
    _feelingDuringDayNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_sleepEnd.isAfter(_sleepStart)) {
      AppFeedback.showError(
        context,
        ValidationError(_sleepEndBeforeStartMessage, fieldErrors: {'sleepEnd': _sleepEndBeforeStartMessage}),
      );
      return;
    }

    final log = SleepLog(
      id: widget.log?.id ?? _uuid.v4(),
      createdAt: widget.log?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'current_user_id',
      sleepStart: _sleepStart,
      sleepEnd: _sleepEnd,
      nightWakeCount: _nightWakeCount,
      feelingBeforeSleep: _feelingBeforeSleep,
      feelingBeforeSleepNote:
          _feelingBeforeSleepNoteController.text.trim().isEmpty ? null : _feelingBeforeSleepNoteController.text.trim(),
      feelingOnWakeup: _feelingOnWakeup,
      feelingOnWakeupNote:
          _feelingOnWakeupNoteController.text.trim().isEmpty ? null : _feelingOnWakeupNoteController.text.trim(),
      feelingDuringDay: _feelingDuringDay,
      feelingDuringDayNote:
          _feelingDuringDayNoteController.text.trim().isEmpty ? null : _feelingDuringDayNoteController.text.trim(),
      lastCaffeineTime: _lastCaffeineTime,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final result = widget.log == null ? await _service.create(log) : await _service.update(log);

    if (!mounted) return;
    if (result.isSuccess) {
      AppFeedback.showSuccess(context, 'Sleep log ${widget.log == null ? 'added' : 'updated'}');
      Navigator.of(context).pop(true);
    } else {
      AppFeedback.showError(context, result.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? 'Add Sleep Log' : 'Edit Sleep Log'),
      ),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DateTimeField(
                label: 'Sleep start',
                value: _sleepStart,
                mode: DateTimeFieldMode.dateTime,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sleepStart = value);
                  }
                },
              ),
              SizedBox(height: tokens.spacing.md),
              DateTimeField(
                label: 'Sleep end',
                value: _sleepEnd,
                mode: DateTimeFieldMode.dateTime,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sleepEnd = value);
                  }
                },
              ),
              if (!_sleepEnd.isAfter(_sleepStart))
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.sm),
                  child: Text(
                    _sleepEndBeforeStartMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              SizedBox(height: tokens.spacing.lg),
              Row(
                children: [
                  const Icon(Icons.nightlight_outlined),
                  SizedBox(width: tokens.spacing.md),
                  const Text('Night wake-ups'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _nightWakeCount > 0
                        ? () => setState(() => _nightWakeCount -= 1)
                        : null,
                  ),
                  Text('$_nightWakeCount', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _nightWakeCount += 1),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.lg),
              _FeelingRatingField(
                label: 'Feeling before sleep',
                rating: _feelingBeforeSleep,
                onChanged: (value) => setState(() => _feelingBeforeSleep = value),
                noteController: _feelingBeforeSleepNoteController,
              ),
              SizedBox(height: tokens.spacing.lg),
              _FeelingRatingField(
                label: 'Feeling on wakeup',
                rating: _feelingOnWakeup,
                onChanged: (value) => setState(() => _feelingOnWakeup = value),
                noteController: _feelingOnWakeupNoteController,
              ),
              SizedBox(height: tokens.spacing.lg),
              _FeelingRatingField(
                label: 'Feeling during day',
                rating: _feelingDuringDay,
                onChanged: (value) => setState(() => _feelingDuringDay = value),
                noteController: _feelingDuringDayNoteController,
              ),
              SizedBox(height: tokens.spacing.lg),
              DateTimeField(
                label: 'Last caffeine time (optional)',
                value: _lastCaffeineTime,
                mode: DateTimeFieldMode.dateTime,
                isClearable: true,
                onChanged: (value) => setState(() => _lastCaffeineTime = value),
              ),
              SizedBox(height: tokens.spacing.md),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              SizedBox(height: tokens.spacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(widget.log == null ? 'Add' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeelingRatingField extends StatelessWidget {
  final String label;
  final int? rating;
  final ValueChanged<int?> onChanged;
  final TextEditingController noteController;

  const _FeelingRatingField({
    required this.label,
    required this.rating,
    required this.onChanged,
    required this.noteController,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: tokens.spacing.xs),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
            ButtonSegment(value: 4, label: Text('4')),
            ButtonSegment(value: 5, label: Text('5')),
          ],
          selected: rating == null ? const {} : {rating!},
          emptySelectionAllowed: true,
          onSelectionChanged: (values) => onChanged(values.isEmpty ? null : values.first),
        ),
        SizedBox(height: tokens.spacing.sm),
        TextFormField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            isDense: true,
          ),
        ),
      ],
    );
  }
}
