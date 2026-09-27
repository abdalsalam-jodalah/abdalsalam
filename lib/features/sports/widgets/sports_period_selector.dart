import 'package:flutter/material.dart';

enum SportsTimePeriod { day, week, month }

class SportsPeriodSelector extends StatelessWidget {
  final SportsTimePeriod selected;
  final ValueChanged<SportsTimePeriod> onChanged;

  const SportsPeriodSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SportsTimePeriod>(
      segments: const [
        ButtonSegment(value: SportsTimePeriod.day, label: Text('Day')),
        ButtonSegment(value: SportsTimePeriod.week, label: Text('Week')),
        ButtonSegment(value: SportsTimePeriod.month, label: Text('Month')),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
