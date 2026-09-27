import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';

const Map<String, IconData> kHabitIconOptions = <String, IconData>{
  'star': Icons.star_outline,
  'fitness': Icons.fitness_center,
  'book': Icons.menu_book_outlined,
  'mosque': Icons.mosque_outlined,
  'water': Icons.water_drop_outlined,
  'food': Icons.restaurant_outlined,
  'sleep': Icons.bedtime_outlined,
  'work': Icons.work_outline,
  'social': Icons.groups_outlined,
  'money': Icons.savings_outlined,
  'warning': Icons.warning_amber_outlined,
  'block': Icons.block_outlined,
};

const String kDefaultHabitIcon = 'star';
const String kDefaultHabitColor = '#2196F3';
const int _kFallbackHabitColorValue = 0xFF2196F3;

const List<String> kHabitMoodLabels = <String>['Great', 'Good', 'Neutral', 'Low', 'Bad'];

/// Maps a named mood label to a 1..5 numeric score for charting (Great=5..Bad=1).
double? habitMoodScore(String? mood) {
  final index = kHabitMoodLabels.indexOf(mood ?? '');
  if (index == -1) {
    return null;
  }
  return (kHabitMoodLabels.length - index).toDouble();
}

Color habitColorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final parsed = int.tryParse(normalized.length == 6 ? 'FF$normalized' : normalized, radix: 16);
  return Color(parsed ?? _kFallbackHabitColorValue);
}

String habitColorToHex(Color color) {
  final value = ((color.a * 255).round() << 24) |
      ((color.r * 255).round() << 16) |
      ((color.g * 255).round() << 8) |
      (color.b * 255).round();
  return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class HabitIconPickerField extends StatelessWidget {
  static const double _selectedBorderWidth = 2;
  static const double _unselectedBorderWidth = 1;

  final String selectedIcon;
  final ValueChanged<String> onChanged;

  const HabitIconPickerField({super.key, required this.selectedIcon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.sm,
      children: kHabitIconOptions.entries.map((entry) {
        final isSelected = entry.key == selectedIcon;
        return InkWell(
          onTap: () => onChanged(entry.key),
          borderRadius: tokens.radius.mediumBorder,
          child: Container(
            padding: EdgeInsets.all(tokens.spacing.sm),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? _selectedBorderWidth : _unselectedBorderWidth,
              ),
              borderRadius: tokens.radius.mediumBorder,
            ),
            child: Icon(entry.value, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}

class HabitColorPickerField extends StatelessWidget {
  static const double _swatchDiameter = 24;
  static const String _pickColorTitle = 'Pick a color';
  static const String _selectLabel = 'Select';
  static const String _chooseColorLabel = 'Choose color';

  final String selectedColorHex;
  final ValueChanged<String> onChanged;

  const HabitColorPickerField({super.key, required this.selectedColorHex, required this.onChanged});

  Future<void> _openPicker(BuildContext context) async {
    var pickerColor = habitColorFromHex(selectedColorHex);
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AppFormDialog(
          title: _pickColorTitle,
          submitLabel: _selectLabel,
          onSubmit: () => Navigator.of(dialogContext).pop(pickerColor),
          child: HueRingPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
          ),
        );
      },
    );
    if (result != null) {
      onChanged(habitColorToHex(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final color = habitColorFromHex(selectedColorHex);
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: tokens.radius.mediumBorder,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md, vertical: tokens.spacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: tokens.radius.mediumBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _swatchDiameter,
              height: _swatchDiameter,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
            ),
            SizedBox(width: tokens.spacing.sm),
            Text(_chooseColorLabel, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
