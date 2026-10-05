// lib/features/sync/widgets/sync_pin_card.dart — Mac link controls: start/stop button, big PIN and link state.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../providers/sync_link_state.dart';

class SyncPinCard extends StatelessWidget {
  static const double _pinFontSize = 48;
  static const double _pinLetterSpacing = 8;

  final String? pin;
  final SyncLinkState linkState;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const SyncPinCard({
    super.key,
    required this.pin,
    required this.linkState,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final currentPin = pin;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentPin != null) ...[
            Text(SyncUiText.pinLabel, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
            SelectableText(
              currentPin,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: _pinFontSize,
                letterSpacing: _pinLetterSpacing,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              SyncUiText.pinHint,
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spacing.md),
          ],
          Text(_stateText(linkState), style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
          SizedBox(height: tokens.spacing.md),
          if (currentPin == null)
            FilledButton.icon(
              onPressed: linkState == SyncLinkState.starting ? null : onStart,
              icon: const Icon(Icons.link_rounded),
              label: const Text(SyncUiText.startLinkLabel),
            )
          else
            OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text(SyncUiText.stopLinkLabel),
            ),
        ],
      ),
    );
  }

  String _stateText(SyncLinkState state) {
    return switch (state) {
      SyncLinkState.stopped => SyncUiText.linkStopped,
      SyncLinkState.starting => SyncUiText.linkStarting,
      SyncLinkState.waiting => SyncUiText.linkWaiting,
      SyncLinkState.syncing => SyncUiText.linkSyncing,
      SyncLinkState.completed => SyncUiText.linkCompleted,
      SyncLinkState.failed => SyncUiText.linkFailed,
    };
  }
}
