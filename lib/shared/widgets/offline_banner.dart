import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class OfflineBanner extends StatelessWidget {
  static const String _message = 'Offline mode: changes will sync when connection is restored.';
  static const double _backgroundTintOpacity = 0.16;

  final bool isOffline;

  const OfflineBanner({super.key, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    if (!isOffline) {
      return const SizedBox.shrink();
    }

    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md, vertical: tokens.spacing.sm),
      decoration: BoxDecoration(
        color: tokens.colors.warning.withValues(alpha: _backgroundTintOpacity),
        borderRadius: tokens.radius.mediumBorder,
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: tokens.colors.warning, size: tokens.spacing.lg),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Text(
              _message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
