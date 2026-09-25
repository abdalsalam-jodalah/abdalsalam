import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_tokens.dart';

class ChartFrame extends StatelessWidget {
  static const double defaultHeight = 220;
  static const String _emptyMessage = 'No data yet';

  final bool isEmpty;
  final double height;
  final Widget child;

  const ChartFrame({super.key, required this.isEmpty, required this.child, this.height = defaultHeight});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return SizedBox(
      height: height,
      child: isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, color: tokens.colors.muted),
                  SizedBox(height: tokens.spacing.xs),
                  Text(_emptyMessage, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens.colors.muted)),
                ],
              ),
            )
          : Padding(padding: EdgeInsets.only(top: tokens.spacing.sm), child: child),
    );
  }
}
