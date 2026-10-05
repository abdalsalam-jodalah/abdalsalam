// lib/features/sync/widgets/sync_connection_card.dart — shows whether adb and the phone are ready on the Mac side.

import 'package:flutter/material.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../services/adb_status.dart';

class SyncConnectionCard extends StatelessWidget {
  final AdbStatus? status;
  final bool isChecking;
  final VoidCallback onCheckAgain;

  const SyncConnectionCard({super.key, required this.status, required this.isChecking, required this.onCheckAgain});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final presentation = _presentationFor(status, tokens);
    return AppCard(
      accentColor: presentation.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(presentation.icon, color: presentation.color),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(presentation.title, style: theme.textTheme.titleMedium),
                    SizedBox(height: tokens.spacing.xs),
                    Text(presentation.message, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.md),
          OutlinedButton.icon(
            onPressed: isChecking ? null : onCheckAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(SyncUiText.checkAgainLabel),
          ),
        ],
      ),
    );
  }

  _ConnectionPresentation _presentationFor(AdbStatus? status, AppThemeTokens tokens) {
    if (status == null) {
      return _ConnectionPresentation(Icons.usb_rounded, tokens.colors.muted, SyncUiText.checkingTitle, '');
    }
    return switch (status.kind) {
      AdbStatusKind.adbMissing => _ConnectionPresentation(
        Icons.error_outline_rounded,
        tokens.colors.danger,
        SyncUiText.adbMissingTitle,
        SyncUiText.adbMissingMessage,
      ),
      AdbStatusKind.commandFailed => _ConnectionPresentation(
        Icons.error_outline_rounded,
        tokens.colors.danger,
        SyncUiText.adbFailedTitle,
        SyncUiText.adbFailedMessage,
      ),
      AdbStatusKind.noDevice => _ConnectionPresentation(
        Icons.usb_off_rounded,
        tokens.colors.warning,
        SyncUiText.noDeviceTitle,
        SyncUiText.noDeviceMessage,
      ),
      AdbStatusKind.offline => _ConnectionPresentation(
        Icons.usb_off_rounded,
        tokens.colors.warning,
        SyncUiText.offlineTitle,
        SyncUiText.offlineMessage,
      ),
      AdbStatusKind.unauthorized => _ConnectionPresentation(
        Icons.lock_outline_rounded,
        tokens.colors.warning,
        SyncUiText.unauthorizedTitle,
        SyncUiText.unauthorizedMessage,
      ),
      AdbStatusKind.ready => _ConnectionPresentation(
        Icons.usb_rounded,
        tokens.colors.success,
        SyncUiText.readyTitle,
        '${SyncUiText.readyMessagePrefix}${status.deviceSerial}',
      ),
    };
  }
}

class _ConnectionPresentation {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _ConnectionPresentation(this.icon, this.color, this.title, this.message);
}
