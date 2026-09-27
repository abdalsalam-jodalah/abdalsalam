import 'package:flutter/material.dart';

import '../../../shared/widgets/ui/app_form_dialog.dart';

class TransactionDeleteDialog extends StatefulWidget {
  static const String title = 'Delete Transaction';
  static const String message = 'Are you sure you want to delete this transaction?';
  static const String confirmLabel = 'Delete';

  final Future<void> Function() onConfirm;

  const TransactionDeleteDialog({super.key, required this.onConfirm});

  @override
  State<TransactionDeleteDialog> createState() => _TransactionDeleteDialogState();
}

class _TransactionDeleteDialogState extends State<TransactionDeleteDialog> {
  bool _isDeleting = false;

  Future<void> _handleConfirm() async {
    setState(() => _isDeleting = true);
    await widget.onConfirm();
    if (mounted) setState(() => _isDeleting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      title: TransactionDeleteDialog.title,
      submitLabel: TransactionDeleteDialog.confirmLabel,
      isSubmitting: _isDeleting,
      onSubmit: _handleConfirm,
      child: const Text(TransactionDeleteDialog.message),
    );
  }
}
