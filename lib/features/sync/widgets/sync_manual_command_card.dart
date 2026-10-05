// lib/features/sync/widgets/sync_manual_command_card.dart — copyable fallback adb command when the Mac app cannot run adb itself.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/sync_ui_text.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/ui/app_card.dart';

class SyncManualCommandCard extends StatelessWidget {
  static const String _monospaceFontFamily = 'monospace';

  final String command;
  final String? failureReason;

  const SyncManualCommandCard({super.key, required this.command, this.failureReason});

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return AppCard(
      accentColor: tokens.colors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SyncUiText.manualCommandTitle, style: theme.textTheme.titleMedium),
          SizedBox(height: tokens.spacing.xs),
          Text(SyncUiText.manualCommandMessage, style: theme.textTheme.bodyMedium),
          if (failureReason != null) ...[
            SizedBox(height: tokens.spacing.xs),
            Text(
              '${SyncUiText.manualCommandFailurePrefix}$failureReason',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.colors.muted),
            ),
          ],
          SizedBox(height: tokens.spacing.md),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  command,
                  style: theme.textTheme.titleSmall?.copyWith(fontFamily: _monospaceFontFamily),
                ),
              ),
              IconButton(
                tooltip: SyncUiText.copyCommandTooltip,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (!context.mounted) return;
    AppFeedback.showSuccess(context, SyncUiText.commandCopiedMessage);
  }
}
