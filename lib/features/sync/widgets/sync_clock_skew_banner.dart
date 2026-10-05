// lib/features/sync/widgets/sync_clock_skew_banner.dart — warns that device clocks differ enough to risk wrong newest-wins merges.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';

class SyncClockSkewBanner extends StatelessWidget {
  const SyncClockSkewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return AppCard(
      accentColor: tokens.colors.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: tokens.colors.warning),
          SizedBox(width: tokens.spacing.md),
          const Expanded(child: Text(SyncUiText.clockSkewWarning)),
        ],
      ),
    );
  }
}
