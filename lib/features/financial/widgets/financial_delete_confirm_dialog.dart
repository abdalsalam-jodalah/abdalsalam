// lib/features/financial/widgets/financial_delete_confirm_dialog.dart: shared stay-open-on-failure delete confirmation for the financial module.
import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/result/result.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/icon_badge.dart';

Future<void> showFinancialDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String deleteLabel,
  required Future<Result<void, AppError>> Function() onConfirm,
  required VoidCallback onDeleted,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final tokens = AppThemeTokens.of(dialogContext);
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: IconBadge(icon: Icons.delete_outline_rounded, color: tokens.colors.danger),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              final result = await onConfirm();
              if (!dialogContext.mounted) return;
              if (result.isSuccess) {
                Navigator.pop(dialogContext);
                onDeleted();
              } else {
                AppFeedback.showError(dialogContext, result.error!);
              }
            },
            child: Text(deleteLabel),
          ),
        ],
      );
    },
  );
}
