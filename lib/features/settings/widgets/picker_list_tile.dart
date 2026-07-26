import 'package:flutter/material.dart';

class PickerOption<T> {
  final T value;
  final String label;

  const PickerOption(this.value, this.label);
}

class PickerListTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<PickerOption<T>> options;
  final IconData? icon;
  final ValueChanged<T> onChanged;

  const PickerListTile({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  String get _currentLabel => options
      .firstWhere(
        (option) => option.value == value,
        orElse: () => PickerOption(value, value.toString()),
      )
      .label;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showDialog<T>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(title),
          children: [
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(option.value),
                child: Row(
                  children: [
                    if (option.value == value)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(option.label),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(_currentLabel),
      trailing: Icon(icon ?? Icons.chevron_right),
      onTap: () => _openPicker(context),
    );
  }
}
