import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class AppFormDialog extends StatelessWidget {
  static const String _defaultCancelLabel = 'Cancel';
  static const double _maxWidth = 520;
  static const double _progressSize = 18;
  static const double _progressStroke = 2;

  final String title;
  final Widget child;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool isSubmitting;
  final String cancelLabel;
  final List<Widget> extraActions;

  const AppFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.submitLabel,
    required this.onSubmit,
    this.isSubmitting = false,
    this.cancelLabel = _defaultCancelLabel,
    this.extraActions = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final spacing = AppThemeTokens.of(context).spacing;
    return AlertDialog(
      title: Text(title),
      contentPadding: EdgeInsets.fromLTRB(spacing.xl, spacing.lg, spacing.xl, spacing.sm),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SingleChildScrollView(child: child),
      ),
      actions: [
        ...extraActions,
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).maybePop(),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: isSubmitting ? null : onSubmit,
          child: isSubmitting
              ? const SizedBox.square(
                  dimension: _progressSize,
                  child: CircularProgressIndicator(strokeWidth: _progressStroke),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}
