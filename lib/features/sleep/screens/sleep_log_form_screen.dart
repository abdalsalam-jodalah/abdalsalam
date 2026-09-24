import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/models/sleep/sleep_log.dart';
import '../../../shared/widgets/app_feedback.dart';
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

  Future<void> _pickDateTime(DateTime initial, ValueChanged<DateTime> onPick) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    onPick(DateTime(date.year, date.month, date.day, time.hour, time.minute));
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

  String _formatDateTime(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? 'Add Sleep Log' : 'Edit Sleep Log'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _DateTimeField(
                label: 'Sleep start',
                dateTime: _sleepStart,
                display: _formatDateTime(_sleepStart),
                onPick: () => _pickDateTime(_sleepStart, (value) => setState(() => _sleepStart = value)),
              ),
              const SizedBox(height: 12),
              _DateTimeField(
                label: 'Sleep end',
                dateTime: _sleepEnd,
                display: _formatDateTime(_sleepEnd),
                onPick: () => _pickDateTime(_sleepEnd, (value) => setState(() => _sleepEnd = value)),
              ),
              if (!_sleepEnd.isAfter(_sleepStart))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Sleep end must be after sleep start.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.nightlight_outlined),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 16),
              _FeelingRatingField(
                label: 'Feeling before sleep',
                rating: _feelingBeforeSleep,
                onChanged: (value) => setState(() => _feelingBeforeSleep = value),
                noteController: _feelingBeforeSleepNoteController,
              ),
              const SizedBox(height: 16),
              _FeelingRatingField(
                label: 'Feeling on wakeup',
                rating: _feelingOnWakeup,
                onChanged: (value) => setState(() => _feelingOnWakeup = value),
                noteController: _feelingOnWakeupNoteController,
              ),
              const SizedBox(height: 16),
              _FeelingRatingField(
                label: 'Feeling during day',
                rating: _feelingDuringDay,
                onChanged: (value) => setState(() => _feelingDuringDay = value),
                noteController: _feelingDuringDayNoteController,
              ),
              const SizedBox(height: 16),
              _DateTimeField(
                label: 'Last caffeine time (optional)',
                dateTime: _lastCaffeineTime,
                display: _lastCaffeineTime == null ? 'Not set' : _formatDateTime(_lastCaffeineTime!),
                onPick: () => _pickDateTime(
                  _lastCaffeineTime ?? _sleepStart,
                  (value) => setState(() => _lastCaffeineTime = value),
                ),
                onClear: _lastCaffeineTime == null ? null : () => setState(() => _lastCaffeineTime = null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 20),
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

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? dateTime;
  final String display;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _DateTimeField({
    required this.label,
    required this.dateTime,
    required this.display,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      leading: const Icon(Icons.access_time),
      title: Text(label),
      subtitle: Text(display),
      trailing: onClear != null
          ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
          : null,
      onTap: onPick,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
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
        const SizedBox(height: 8),
        TextFormField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
