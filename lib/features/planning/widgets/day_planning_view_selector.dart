import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../services/day_planning_view_mode.dart';

class DayPlanningViewSelector extends StatelessWidget {
  final DayPlanningViewMode mode;
  final int customDays;
  final ValueChanged<DayPlanningViewMode> onModeChanged;
  final VoidCallback onEditCustomDays;

  const DayPlanningViewSelector({
    super.key,
    required this.mode,
    required this.customDays,
    required this.onModeChanged,
    required this.onEditCustomDays,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<DayPlanningViewMode>(
            showSelectedIcon: false,
            segments: [
              for (final option in DayPlanningViewMode.values)
                ButtonSegment<DayPlanningViewMode>(value: option, label: Text(option.label)),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onModeChanged(selection.first),
          ),
        ),
        if (mode == DayPlanningViewMode.custom)
          Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: ActionChip(
              avatar: const Icon(Icons.edit_outlined),
              label: Text('$customDays ${customDays == 1 ? 'day' : 'days'}'),
              onPressed: onEditCustomDays,
            ),
          ),
      ],
    );
  }
}
