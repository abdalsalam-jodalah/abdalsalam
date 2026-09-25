import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    builder: (sheetContext) {
      final spacing = AppThemeTokens.of(sheetContext).spacing;
      return Padding(
        padding: EdgeInsets.only(
          left: spacing.lg,
          right: spacing.lg,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child: Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              ),
            Flexible(child: builder(sheetContext)),
          ],
        ),
      );
    },
  );
}
