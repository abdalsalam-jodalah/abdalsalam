import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/ui/app_form_dialog.dart';
import '../services/day_planning_range.dart';

Future<int?> showCustomDaysDialog(BuildContext context, {required int initialDays}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _CustomDaysDialogContent(initialDays: initialDays),
  );
}

class _CustomDaysDialogContent extends StatefulWidget {
  final int initialDays;

  const _CustomDaysDialogContent({required this.initialDays});

  @override
  State<_CustomDaysDialogContent> createState() => _CustomDaysDialogContentState();
}

class _CustomDaysDialogContentState extends State<_CustomDaysDialogContent> {
  static const String _title = 'Custom range';
  static const String _submitLabel = 'Apply';
  static const String _fieldLabel = 'Number of days';
  static const String _invalidMessage =
      'Enter a number between ${DayPlanningRange.minCustomDays} and ${DayPlanningRange.maxCustomDays}';

  final formKey = GlobalKey<FormState>();
  late final TextEditingController daysController = TextEditingController(text: widget.initialDays.toString());

  @override
  void dispose() {
    daysController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final days = int.tryParse(value?.trim() ?? '');
    final isInRange = days != null && days >= DayPlanningRange.minCustomDays && days <= DayPlanningRange.maxCustomDays;
    return isInRange ? null : _invalidMessage;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, int.parse(daysController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: _title,
      submitLabel: _submitLabel,
      onSubmit: _submit,
      child: Form(
        key: formKey,
        child: TextFormField(
          controller: daysController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: _fieldLabel),
          validator: _validate,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
