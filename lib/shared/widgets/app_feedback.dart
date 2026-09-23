import 'package:flutter/material.dart';

import '../services/user_error_message_mapper.dart';

class AppFeedback {
  static const UserErrorMessageMapper _messageMapper = UserErrorMessageMapper();

  const AppFeedback._();

  static void showError(BuildContext context, Object error) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: _messageMapper.toUserMessage(error),
      backgroundColor: colorScheme.error,
      foregroundColor: colorScheme.onError,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    _show(
      context,
      message: message,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: foregroundColor)),
          backgroundColor: backgroundColor,
        ),
      );
  }
}
