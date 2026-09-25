import 'package:flutter/material.dart';

import '../../../core/formatting/app_date_formatter.dart';
import '../../../core/theme/app_theme_tokens.dart';

enum DateTimeFieldMode { date, time, dateTime }

class DateTimeField extends StatelessWidget {
  static const String _placeholder = 'Not set';
  static const String _clearTooltip = 'Clear';
  static const int _yearsRange = 50;

  final String label;
  final DateTime? value;
  final DateTimeFieldMode mode;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isClearable;
  final String? errorText;

  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.mode = DateTimeFieldMode.date,
    this.firstDate,
    this.lastDate,
    this.isClearable = false,
    this.errorText,
  });

  IconData get _icon => switch (mode) {
        DateTimeFieldMode.time => Icons.schedule_rounded,
        DateTimeFieldMode.date => Icons.calendar_today_rounded,
        DateTimeFieldMode.dateTime => Icons.event_rounded,
      };

  String _format(DateTime selected) => switch (mode) {
        DateTimeFieldMode.date => AppDateFormatter.date(selected),
        DateTimeFieldMode.time => AppDateFormatter.time(selected),
        DateTimeFieldMode.dateTime => AppDateFormatter.dateTime(selected),
      };

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;
    var picked = initial;
    if (mode != DateTimeFieldMode.time) {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate ?? DateTime(now.year - _yearsRange),
        lastDate: lastDate ?? DateTime(now.year + _yearsRange),
      );
      if (date == null || !context.mounted) {
        return;
      }
      picked = DateTime(date.year, date.month, date.day, initial.hour, initial.minute);
    }
    if (mode != DateTimeFieldMode.date) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time == null || !context.mounted) {
        return;
      }
      picked = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    }
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = value;
    return InkWell(
      borderRadius: AppThemeTokens.of(context).radius.mediumBorder,
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: Icon(_icon),
          suffixIcon: isClearable && selected != null
              ? IconButton(
                  tooltip: _clearTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(selected == null ? _placeholder : _format(selected)),
      ),
    );
  }
}
