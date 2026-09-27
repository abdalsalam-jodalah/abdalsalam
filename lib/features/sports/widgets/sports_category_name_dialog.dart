import 'package:flutter/material.dart';

import '../../../data/models/sports/exercise_category.dart';
import '../../../shared/widgets/ui/app_form_dialog.dart';

Future<String?> showSportsCategoryNameDialog(BuildContext context, {ExerciseCategory? category}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryNameDialogContent(category: category),
  );
}

class _CategoryNameDialogContent extends StatefulWidget {
  const _CategoryNameDialogContent({required this.category});

  final ExerciseCategory? category;

  @override
  State<_CategoryNameDialogContent> createState() => _CategoryNameDialogContentState();
}

class _CategoryNameDialogContentState extends State<_CategoryNameDialogContent> {
  static const String _newTitle = 'New Category';
  static const String _editTitle = 'Edit Category';
  static const String _createLabel = 'Create';
  static const String _saveLabel = 'Save';
  static const String _requiredMessage = 'Required';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;
    return AppFormDialog(
      title: isNew ? _newTitle : _editTitle,
      submitLabel: isNew ? _createLabel : _saveLabel,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) => (value == null || value.trim().isEmpty) ? _requiredMessage : null,
        ),
      ),
    );
  }
}
