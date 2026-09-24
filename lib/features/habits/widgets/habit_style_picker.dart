import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  final String selectedIcon;
  final ValueChanged<String> onChanged;

  const HabitIconPickerField({super.key, required this.selectedIcon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kHabitIconOptions.entries.map((entry) {
        final isSelected = entry.key == selectedIcon;
        return InkWell(
          onTap: () => onChanged(entry.key),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(entry.value),
          ),
        );
      }).toList(),
    );
  }
}

class HabitColorPickerField extends StatelessWidget {
  final String selectedColorHex;
  final ValueChanged<String> onChanged;

  const HabitColorPickerField({super.key, required this.selectedColorHex, required this.onChanged});

  Future<void> _openPicker(BuildContext context) async {
    var pickerColor = habitColorFromHex(selectedColorHex);
    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: HueRingPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(pickerColor),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      onChanged(habitColorToHex(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = habitColorFromHex(selectedColorHex);
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Choose color'),
          ],
        ),
      ),
    );
  }
}
