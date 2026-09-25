import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';
import 'icon_badge.dart';

const String _defaultCancelLabel = 'Cancel';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = _defaultCancelLabel,
  bool isDestructive = false,
  IconData? icon,
}) async {
  final isConfirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final tokens = AppThemeTokens.of(dialogContext);
      final colorScheme = Theme.of(dialogContext).colorScheme;
      final accent = isDestructive ? tokens.colors.danger : colorScheme.primary;
      return AlertDialog(
        icon: icon == null ? null : IconBadge(icon: icon, color: accent),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(cancelLabel)),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError)
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return isConfirmed ?? false;
}
